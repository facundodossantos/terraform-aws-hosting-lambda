function handler(event) {
  var response = event.response;
  var headers  = response.headers;

  var websiteRedirectLocationHeader = headers['x-amz-website-redirect-location'];

  if (websiteRedirectLocationHeader && websiteRedirectLocationHeader.value) {
    response.statusCode = 301;
    response.statusDescription = 'Moved Permanently';
    headers['location'] = { value: websiteRedirectLocationHeader.value };

    delete headers['x-amz-website-redirect-location'];
    delete headers['content-type'];
  }

  return response;
}
