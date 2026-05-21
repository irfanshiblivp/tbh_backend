from django.db import migrations


def add_users_state_column(apps, schema_editor):
    # Unmanaged models are not altered automatically; patch legacy table directly.
    if schema_editor.connection.vendor != 'mysql':
        return

    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SHOW COLUMNS FROM users LIKE 'state'")
        exists = cursor.fetchone() is not None
        if not exists:
            cursor.execute("ALTER TABLE users ADD COLUMN state VARCHAR(255) NULL")


def remove_users_state_column(apps, schema_editor):
    if schema_editor.connection.vendor != 'mysql':
        return

    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SHOW COLUMNS FROM users LIKE 'state'")
        exists = cursor.fetchone() is not None
        if exists:
            cursor.execute("ALTER TABLE users DROP COLUMN state")


class Migration(migrations.Migration):

    dependencies = [
        ('app_api', '0008_alter_appsetting_table_alter_category_table_and_more'),
    ]

    operations = [
        migrations.RunPython(add_users_state_column, remove_users_state_column),
    ]
