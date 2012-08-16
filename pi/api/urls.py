from django.conf.urls import patterns, include, url

urlpatterns = patterns('api.views',
    # Examples:
    url(r'^$', 'query', name='home'),
    #url(r'^light_control/', include('light_control.frontend.urls')),
    url(r'^query/', 'query'),
)
