"""Example script demonstrating a fallback notification directive handler.

This handler tries to handle all directives by formatting a simple email
with the event information in CSV format where the columns are limited
to event attributes that should be present in almost all events.
"""


def create_notifications(context):
    # always create notifications, never postpone

    # If there are some additional substitutions to be performed in the
    # above template, add them to the substitutions dictionary. By
    # passing it to the mail_format_as_csv method below they will be
    # substituted into the template when the mail is created.
    data_format = context.directive.event_data_format
    if data_format.endswith("_csv_attachment"):
        return context.mail_format_as_csv(substitutions={},
                                          attach_event_data=True)
    else:
        return context.mail_format_as_csv(substitutions={})
