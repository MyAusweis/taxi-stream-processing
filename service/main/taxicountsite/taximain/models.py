from django.db import models

# Create your models here.
class TaxiCountEntry(models.Model):
    creation_date = models.DateTimeField(db_index=True, auto_now_add=True)
    counts = models.IntegerField(default=0)
