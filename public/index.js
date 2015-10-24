var httpget = function(url, callback) {
  var xhr = new XMLHttpRequest;
  xhr.open('GET', url, true);
  xhr.onreadystatechange = function() {
    if (xhr.readyState === 4) {
      if (xhr.status === 200) {
        callback(null, xhr.responseText);
      } else {
        callback(new Error(xhr.status), xhr.responseText);
      }
    }
  }
  xhr.send(null);
}

var audioPlayerHTML = function(url) {
  return "<audio controls=controls autoplay>" +
    "<source src='" + url + "'>" +
    "</audio>"
};

var from_related = function(el) {
  var url = el.href;
  document.querySelector('#url').value = unescape(url);
  go(unescape(url));
  return false;
}

var go = function(url) {
  document.querySelector('#audio-player').innerHTML = audioPlayerHTML(
    'get-audio-stream?url=' + encodeURIComponent(url)
  );
  document.querySelector('#related').innerHTML = '';
  httpget("get-related?url=" + encodeURIComponent(url),
    function(err,res) {
    if (err) {
      alert("get-related: GOT ERROR: " + err.message);
    } else {
      var related = document.querySelector('#related');
      var html = "<ul><li>" + JSON.parse(res).map(function(el) {
        return "<a href='https://www.youtube.com" + el.href +
          "' onclick='return from_related(this)' class=related>" +
          el.title + "</a>";
      }).join("</li><li>") + "</li></ul>";
      related.innerHTML = html;
    }
  })
}

window.onload = function() {
  document
    .querySelector('#url')
    .addEventListener('keypress', function(event) {
      if (event.which === 10 || event.which === 13) {
        go(this.value);
      }
  }, false)
}
