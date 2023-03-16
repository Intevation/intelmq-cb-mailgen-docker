# this is an adapted copy of intelmq-certbund-contact/example-rules/32ct_vulnerable-service.py
# changes:
# - aggregates by taxonomy
# - considers extra.template_prefix for the template
from intelmq_certbund_contact.rulesupport import \
    Directive, most_specific_matches

# A set which is containing information about already logged
# errors to prevent log-flooding
LOGGING_SET = set()


def determine_directives(context):
    context.logger.debug("============= 10oneshot.py ===========")

    classification_identifier = context.get("classification.identifier")
    classification_type = context.get("classification.type")

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
    return True


def add_directives_to_context(context, matches, matter):
    # Generate Directives from the matches

    context.logger.debug('%r', matches)
    for match in matches:
        # Iterate the matches...
        # Matches tell us the organisations and their contacts that
        # could be determined for a property of the event, such as
        # IP-Address, ASN, CC.
        # It can happen that one organisation has multiple matches for
        # the same criterion (for instance IP - address),
        # this happens due to overlapping networks in the
        # contactdb
        add_vulnerable_directives_to_context(context, match, matter)


def add_vulnerable_directives_to_context(context, match, matter):
    # Let's have a look at the Organisations associated to this match:
    context.logger.debug('%r', context.organisations_for_match(match))
    for org in context.organisations_for_match(match):
        # Determine the Annotations for this Org.
        org_annotations = org.annotations
        context.logger.debug("Org Annotations: %r" % org_annotations)

        is_government = False
        is_critical = False

        for annotation in org_annotations:
            if annotation.tag == "government":
                is_government = True
            if annotation.tag == "critical":
                is_critical = True

        # Now create the Directives
        #
        # An organisation may have multiple contacts, so we need to
        # iterate over them. In many cases this will only loop once as
        # many organisations will have only one.
        for contact in org.contacts:
            directive = Directive.from_contact(contact)
            # Doing this defines "email" as medium and uses the
            # contact's email attribute as the recipient_address.
            # One could also do this by hand, see Directive in
            # intelmq.bots.experts.certbund_contact.rulesupport
            # If you like to know more details

            # Now fill in more details of the directive, depending on
            # the annotations of the directive and/or the type of the
            # match

            if is_critical:
                pass  # Right now we are not generating Notifications for this group

            elif is_government:
                pass  # Right now we are not generating Notifications for this group

            elif match.field == "geolocation.cc":
                pass  # Right now we are not generating Notifications for this group

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
