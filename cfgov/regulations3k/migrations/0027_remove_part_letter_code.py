# -*- coding: utf-8 -*-
# Generated by Django 1.11.20 on 2019-06-27 15:06
from __future__ import unicode_literals

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('regulations3k', '0026_migrate_letter_code_to_short_name'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='part',
            name='letter_code',
        ),
    ]
