from re import match as re_match
from intelmq_certbund_contact.rulesupport import \
    Directive, most_specific_matches


def get_contact_format(contact):
    for annotation in contact.annotations:
        m = re_match("^(Format:)(.*)$", annotation.tag)
        if m:
            return m.groups()[1]
    return None


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

    add_directives_to_context(context, msm, "webinput-default")

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
            # Doing this defines "email" as medium and uses the
            # contact's email attribute as the recipient_address.
            # One could also do this by hand, see Directive in
            # intelmq.bots.experts.certbund_contact.rulesupport
            # If you like to know more details
            directive = Directive.from_contact(contact)
            d = create_directive(notification_format="default",
                                 interval=86400,
                                 data_format=matter + "_csv_inline")
            directive.update(d)
            # Add the observation time as an aggregation identifier,
            # in order to cluster all events from the same report-batch.
            directive.aggregate_by_field("time.observation")
            # Always aggregate by Taxonomy
            directive.aggregate_by_field("classification.taxonomy")

            directive.event_data_format = matter + "_csv_inline"
            if get_contact_format(contact) == 'CSV_attachment':
                directive.event_data_format = matter + "_csv_attachment"

            context.add_directive(directive)


def create_directive(notification_format, interval, data_format):
    return Directive(template_name='webinput_fallback_provider',
                     notification_format=notification_format,
                     event_data_format=data_format,
                     notification_interval=interval)
