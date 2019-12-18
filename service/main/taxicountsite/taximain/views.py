from django.shortcuts import render

from django.http import HttpResponse
import json
from datetime import timedelta, datetime
from .models import *
from django.views.decorators.csrf import csrf_exempt, csrf_protect


def get_counts_last1hr(request):
    start_datetime = datetime.now() - timedelta(hours=1)
    objs = TaxiCountEntry.objects.filter(creation_date__gte=start_datetime)
    counts = 0
    for tce in objs:
        counts += tce.counts
    return HttpResponse(json.dumps({"counts":counts}))

@csrf_exempt
def add_counts(request):
    for k in request.POST:
        print(k, request.POST[k])

    posts_data = request.POST
    if "counts" in posts_data:
        # Delete counts older than 1 hour
        start_datetime = datetime.now() - timedelta(hours=1)
        TaxiCountEntry.objects.filter(creation_date__lt=start_datetime).delete()

        counts = posts_data["counts"]
        # Insert into to DB
        tce = TaxiCountEntry(counts=counts)
        tce.save()
        return HttpResponse(json.dumps({"status": 0, "message": "Success"}))

    return HttpResponse(json.dumps({"status": 1, "message": "counts not found the request."}))
