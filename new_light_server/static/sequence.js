function insert_row(button)
{
             //     TD         TR
    var tr=button.parentNode.parentNode;
    var tbody=tr.parentNode;
    if (!tbody) {
        return;
    }
    tbody.insertBefore(tr.cloneNode(true),tr);
    jscolor.bind();
}

function remove_row(button)
{
             //     TD         TR
    var tr=button.parentNode.parentNode;
    var tbody=tr.parentNode;
    if (!tbody) {
        return;
    }
    if (tbody.getElementsByTagName("TR").length == 3) {
        alert("Can't delete last row!");
    } else {
        tbody.removeChild(tr);
    }
}

function copyColor(button)
{
    var tr=button.parentNode.parentNode;
    var color1 = null;
    var color2 = null;
    var cb = null;
    var inputs = tr.getElementsByTagName("INPUT");
    for (var kidindex = 0; kidindex < inputs.length; kidindex++) {
        var kid = inputs[kidindex];
        if (kid.name == 'sequence_color1[]') {
            color1 = kid;
        } else if (kid.name == 'sequence_color2[]') {
            color2 = kid;
        } else if (kid.id == 'cb') {
            cb = kid;
        }
        if (color1 && color2 && cb) {
            break;
        }
    }
    if (!cb.checked) {
        return;
    }
    if (button.type == 'checkbox' || button == color1) {
        color2.color.fromString(color1.color.toString());
    } else {
        color1.color.fromString(color2.color.toString());
    }
}
