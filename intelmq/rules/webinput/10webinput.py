from intelmq_certbund_contact.rulesupport import \
    Directive, most_specific_matches


def determine_directives(context):
    context.logger.debug("============= 10webinput.py ===========")

    if context.section == "destination":
        # We are not interested in notifying the contact for the destination of this event.
        return

    # write the most specific matches into a variable. See
    # 51avalanche.py for a more detailed description.
    msm = most_specific_matches(context)

    # Debugging Output about the Context.
    context.logger.debug("Context Matches: %r", context.matches)
    context.logger.debug("Most Specific Matches: %r",
                         most_specific_matches(context))

    if not msm:
        context.logger.debug("There are no matches I'm willing to process.")
        return

    template = context.get("extra.template_prefix", "oneshot_fallback")
    # Remove the field
    context.pop("extra.template_prefix", None)
    add_directives_to_context(context, msm, template)

    # remove the data which was only relevant up to this step
    if context.get('extra.target_groups') is not None:
        context.pop('extra.target_groups')

    return True


def add_directives_to_context(context, matches, matter):
    # Generate Directives from the matches

    context.logger.debug('add_directives_to_context: Matches: %r', matches)
    for match in matches:
        # Iterate the matches...
        # Matches tell us the organisations and their contacts that
        # could be determined for a property of the event, such as
        # IP-Address, ASN, CC.
        # It can happen that one organisation has multiple matches for
        # the same criterion (for instance IP - address),
        # this happens due to overlapping networks in the
        # contactdb
        add_directives_to_context_per_match(context, match, matter)


def add_directives_to_context_per_match(context, match, matter):
    # Let's have a look at the Organisations associated to this match:
    context.logger.debug('organisations_for_match: %r', context.organisations_for_match(match))
    for org in context.organisations_for_match(match):
        # Now create the Directives
        #
        # An organisation may have multiple contacts, so we need to
        # iterate over them. In many cases this will only loop once as
        # many organisations will have only one.
        for contact in org.contacts:
            directive = Directive.from_contact(contact)
            context.logger.debug('Contact annotations: %r', contact.annotations)

            # if the field exists, assume it does not match
            # if the field does not exist, assume it matches
            target_group_matches = context.get('extra.target_groups') is None
            # only run this block if relevant
            if not target_group_matches:
                for annotation in contact.annotations:
                    context.logger.debug(f'Annotation {annotation.tag!r}')
                    if not annotation.tag.startswith('Target group:'):
                        continue
                    if annotation.tag in context.get('extra.target_groups', []):
                        context.logger.debug('Contact %r matches with contact tag %r the tags of the event %r.', contact.email, annotation, context.get('extra.target_groups', []))
                        target_group_matches = True
                        break

            if not target_group_matches:
                context.logger.debug('Ignoring contact %r as no contact tag %r matches the tags of the event %r.', contact.email, contact.annotations, context.get('extra.target_groups', []))

            else:
                d = create_directive(notification_format="default",
                                     matter=matter,
                                     target_group="provider",
                                     interval=86400,
                                     data_format=matter + "_csv_inline")
                directive.update(d)
                # Add the observation time as an aggregation identifier,
                # in order to cluster all events from the same report-batch.
                directive.aggregate_by_field("time.observation")
                # Always aggregate by Taxonomy
                directive.aggregate_by_field("classification.taxonomy")
                context.add_directive(directive)


def create_directive(notification_format, matter, target_group, interval, data_format):
    """
    This method creates Directives looking like:
    template_name: openportmapper_provider
    notification_format: vulnerable-service
    notification_interval: 86400
    data_format: openportmapper_csv_inline

    """
    return Directive(template_name=matter + "_" + target_group,
                     notification_format=notification_format,
                     event_data_format=data_format,
                     notification_interval=interval)
