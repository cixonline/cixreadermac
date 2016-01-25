tooltipShow = function(event,item) {
    var e = item.getElementsByClassName('tooltip_text')[0];
    var l = event.clientX + 5;
    if (l < 20) l = 20;
    if (l > window.innerWidth - 350) l = window.innerWidth - 350;
    e.style.top = (event.clientY + 20) + 'px';
    e.style.left = l + 'px';
    e.style.display = 'block';
}
tooltipHide = function(event,item) {
    var e = item.getElementsByClassName('tooltip_text')[0];
    e.style.display = 'none';
}
