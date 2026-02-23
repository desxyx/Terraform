exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
    },
    body: `
      <!doctype html>
      <html>
        <head><meta charset="utf-8"><title>Hello</title></head>
        <body style="font-family: Arial; padding: 24px;">
          <h1>Hello World 👋</h1>
          <p>Lambda is running.</p>
        </body>
      </html>
    `,
  };
};
