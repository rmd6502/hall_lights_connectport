function insert_row(button)
{
             //     TD         TR
    tr=button.parentNode.parentNode;
    tbody=tr.parentNode;
    if (!tbody) {
        return;
    }
    tbody.insertBefore(tr,tr.cloneNode(true));
}

function delete_row(button)
{
             //     TD         TR
    tr=button.parentNode.parentNode;
    tbody=tr.parentNode;
    if (!tbody) {
        return;
    }
    if (tbody.getElementsByTagName("TR").length == 1) {
        alert("Can't delete last row!");
    } else {
        tbody.removeChild(tr);
    }
}
