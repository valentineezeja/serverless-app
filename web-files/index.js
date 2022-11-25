exports.handler = async (event) => {
  try {
    switch(event['path']) { case "/": case "/html": case "/html/": case "/index.html": { event['path'] = "/html/index.html"; } }
    var b = false, s = 200, f = require('fs'), d = f.readFileSync("."+event['path'],"binary"), path = event['path'].split("/"), 
      m = new Map([["htm","text/html"],["html","text/html"],["css","text/css"],["ico","image/x-icon"],["js","text/javascript"],
      ["doc","application/msword"],["docx","application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
      ["gif", "image/gif"],["jpg","image/jpeg"],["jpeg","image/jpeg"],["pdf","application/pdf"],["png","image/png"],
      ["ppt","application/vnd.ms-powerpoint"],["pptx","application/vnd.openxmlformats-officedocument.presentationml.presentation"],
      ["svg","image/svg+xml"],["txt","text/plain"],["xls","application/vnd.ms-excel"],["zip","application/zip"],
      ["xlsx","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]]), c = m.get(path[2].split(".")[1]);
    switch(path[1]) { case "img": case "download": { b = true; d = Buffer.from(d,'binary').toString('base64'); } }
  }
  catch (e) { s = 404; c = "text/html", d = f.readFileSync("./html/404.html","binary"); }
  return { statusCode: s, isBase64Encoded: b, headers: {"Content-Type": c}, body: d};
};