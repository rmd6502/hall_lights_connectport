function updateColor(name,button) 
{
    var cb = document.getElementById(name+"_check");
    if (!cb || !cb.checked) {
        return;
    }
    var in1=document.getElementById(name+"_color");
    if (button.valueElement && button.valueElement.id == name+"_color2") {
        in1.color.fromString(button.toString());
    } else {
        var in2=document.getElementById(name+"_color2");
        in2.color.fromString(in1.value);
    }
    if (button == cb) {
        hidden_submit(button.form, null);
    }
}

function hidden_submit(form,control)
{
    if (control && control.color) {
        control.color.hidePicker();
    }
    var action = form.action;
    if (action.length == 0) {
        action = window.location.href;
    }
    var inputs = form.getElementsByTagName("INPUT");
    var conjunct="?";
    for (var i=0; i < inputs.length; ++i) {
        var input = inputs.item(i);
        if (input.name) {
            action = action + conjunct;
            conjunct='&';
            action = action+input.name + "=" + input.value;
        }
    }
    xmlhttp = new XMLHttpRequest();
    xmlhttp.open(form.method, action, false);
    xmlhttp.send();
    return false;
}

function setAllLights(color,form)
{
    var inputs = form.getElementsByTagName("INPUT");
    for (var i=0; i < inputs.length; ++i) {
        var input = inputs.item(i);
        if (input.color) {
            input.color.fromString(color);
        }
    }
    hidden_submit(form, null);
}
