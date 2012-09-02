from django.db import models

# Create your models here.
class Node(models.Model):
    nodeId = models.CharField(max_length=64,primary_key=True)
    nodeName = models.CharField(max_length=64)
    lastActive = models.DateTimeField()

class Light(models.Model):
    node = models.ForeignKey(Node)
    name = models.CharField(max_length=64)
    controller = models.IntegerField("connected to port 1 or 2")
    color = models.CommaSeparatedIntegerField("r,g,b",max_length=12)
