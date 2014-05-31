function insert_row(button)
{
             //     TD         TR
    tr=button.parentNode.parentNode;
    tbody=tr.parentNode;
    if (!tbody) {
        return;
    }
    tbody.insertBefore(tr.cloneNode(true),tr);
}

function remove_row(button)
{
             //     TD         TR
    tr=button.parentNode.parentNode;
    tbody=tr.parentNode;
    if (!tbody) {
        return;
    }
    if (tbody.getElementsByTagName("TR").length == 3) {
        alert("Can't delete last row!");
    } else {
        tbody.removeChild(tr);
    }
}
