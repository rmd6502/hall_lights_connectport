from django.shortcuts import render_to_response
from django.http import Http404
from api.models import  *

# Create your views here.
def query(request):
    nl = Node.objects.all()
    return render_to_response('api/query.xml', {'nodes':nl})
