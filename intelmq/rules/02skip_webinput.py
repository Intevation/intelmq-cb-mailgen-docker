from intelmq_certbund_contact.rulesupport import Directive


def determine_directives(context):
    if context.section == "destination":
        return

    context.logger.debug('Context: %r.', context)
    feed = context.get("feed.name", "")
    if feed.startswith('webinput-csv'):
        context.logger.info('Oneshot detected!')
        return True
    return
