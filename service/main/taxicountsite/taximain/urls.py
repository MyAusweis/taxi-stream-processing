from django.urls import path

from . import views

urlpatterns = [
    path('', views.get_counts_last1hr, name='get_counts_last1hr'),
    path('add_counts', views.add_counts, name='add_counts'),
]
