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
    context.logger.debug("============= 05target_groups.py ===========")

    if context.get('extra.target_groups') is None:
        context.logger.info('Event has no information about target groups, skipping.')
        return

    matching_organisations = []

    for org in context.organisations:
        # Now create the Directives
        #
        # An organisation may have multiple contacts, so we need to
        # iterate over them. In many cases this will only loop once as
        # many organisations will have only one.

        filtered_contacts = []

        for contact in org.contacts:
            directive = Directive.from_contact(contact)
            context.logger.debug('Contact %r annotations: %r', contact.email, contact.annotations)

            recipient_format = get_contact_format(contact)

            for annotation in contact.annotations:
                if not annotation.tag.startswith('Target group:'):
                    continue
                if annotation.tag in context.get('extra.target_groups', []):
                    context.logger.debug('Contact %r matches with contact tag %r the tags of the event %r.', contact.email, annotation, context.get('extra.target_groups', []))
                    filtered_contacts.append(contact)
                    break

        if filtered_contacts:
            org.contacts = filtered_contacts
            matching_organisations.append(org)
        
    context.organisations = matching_organisations

    # remove the data which was only relevant up to this step
    context.pop('extra.target_groups')

    # the following scripts will create the directives
    return None