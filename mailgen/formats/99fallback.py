"""Example script demonstrating a fallback notification directive handler.

This handler tries to handle all directives by formatting a simple email
with the event information in CSV format where the columns are limited
to event attributes that should be present in almost all events.
"""

from intelmqmail.tableformat import build_table_format
from intelmqmail.templates import Template
from intelmqmail.notification import Postponed


bcc_contacts = {
    'government': {'recipient': 'abuse@government.example', 'format': 'attached'}
}


table_format = build_table_format(
    "Fallback",
    (("source.asn", "asn"),
     ("source.ip", "ip"),
     ("time.source", "timestamp"),
     ("source.port", "src_port"),
     ("destination.ip", "dst_ip"),
     ("destination.port", "dst_port"),
     ("destination.fqdn", "dst_host"),
     ("protocol.transport", "proto"),
     ))

# The text of the template is inlined here to make sure creating the
# mail does not fail due to a missing template file.
template = Template.from_strings("Report#${ticket_number}",
                                 "Dear Sir or Madam,\n"
                                 "\n"
                                 "Please find below a list of affected systems"
                                 " on your network(s).\n"
                                 "\n"
                                 "Events:\n"
                                 "${events_as_csv}")

def create_notifications(context):
    if not context.notification_interval_exceeded():
        return Postponed

    # If there are some additional substitutions to be performed in the
    # above template, add them to the substitutions dictionary. By
    # passing it to the mail_format_as_csv method below they will be
    # substituted into the template when the mail is created.
    substitutions = dict()

    recipient_group = context.directive.aggregate_identifier.get('recipient_group')
    context.logger.debug(f'Recipient group {recipient_group}')


    notifications = context.mail_format_as_csv(table_format, template=template,
                                      substitutions=substitutions)
    if recipient_group:
        notifications.extend(context.mail_format_as_csv(table_format, template=template,
                                      substitutions=substitutions,
                                      envelope_tos=[bcc_contacts[recipient_group]['recipient']]))
    return notifications
