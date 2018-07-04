---
title: "Cloudflare Edge Side Includes"
date: 2018-07-04T22:25:52+02:00
url: /drafts/f1874a1b6e0e1207e40a453ebaebda11fe052e15
unlist: true
tags:
- case-study
---

Learn about how my client Titel Media was able to use Cloudflare Workers to implement simple edge side includes.

The idea is to partially replace the parts of the online magazine https://www.highsnobiety.com/
with a new, and much more refined frontend implementation.

In this article, you will get to know the use case, and how I found a powerful application for Cloudflare Workers.

<!--more-->

## Backstory

My current project, https://www.highsnobiety.com/ is in the process of replacing Wordpress with
a dedicated content pipeline and a custom frontend.

It is a huge magazine, with tons of contents, hundreds of daily updates and an international team of
more than 60 editors, resarching and writing exciting stories.

The company behind it, Titel Media GmbH, a publishing house with offices in Berlin, and New York,
surely has grown out of Wordpress for hosting their content.

## The show must go on

One does not simply rewrite a sophisticated web publishing pipeline like Wordpress. Nor does one,
simply rewrite a complete frontend in any manageable timeframe and then deploy it safely without
causing any interruptions.

There is an inherent risk in such "big rewrites". They can fail in many spectacular ways. Not getting it
done being one of them, very popular. Failing to live up to high expectations (the ones that also caused the
rewrite), is also well known to shatter the dreams of every project manager.
Or how to manage changing requirements for a transition period of 1+ years?

Our working group, that should solve the transition, layed out a plan to sustainably grow the development team,
while making level for safe path for the future.

* We absolutely did not want to wait 1-2 years, until everything had been rewritten.
* We also, did not want to continue working with Wordpress for the next 5+ years
* And we did not want to interrupt the current publishing pipeline for our editors

You can learn more about the Wordpress migration in my upcoming series about this client. Subscribe below, to stay in touch.

## The idea: Partially rewriting the page

Wordpress is, and was running just fine. Years of dealing with the intricate details of such an installation,
have lead to a pretty mature setup.

Fortunately, there is no pressure from the underlying techology to finish the transition in a hurry.

Time, about 1+ years, is actually on our side. The team is able to contribute changes step by step.

This is when we are incorporating some of the great ideas out there: Edge Side Includes.

I first heard about it, in some office kitchen talks, about how Amazon is apparently never failing,
because so many of their services are backed up by fallbacks. For example, if some part of the page does
not render in time, this part is able to fallback to other fitting content gracefully.

I could never verify these claims, but the idea sure stuck to me.
When requiring high availability, this idea is very appealing.

During the transition period, the idea is to rewrite parts of the website, step by step, and steadily
grow the new frontend while everything is running.

We need two particular features from the ESI toolbox:

1. Includes
    Our new frontend, should be able to render components of the current page. We want to include
    them, and overwrite parts of the page with the new frontend.

2. Fallbacks
    Wordpress, will remain running during the live transition period. Any fragment, that fails,
    can still be taken from Wordpress, and there is a safe fallback to go back to.

<video controls>
  <source src="/cloudflare-edge-side-includes/movie.mp4" type="video/mp4" />
  <img src="/cloudflare-edge-side-includes/video.gif" />
</video>

### Origin HTML document

Lets continue on a simple example. The origin responds with the following HTML document, and the corresponding
`X-Fragment` headers:

```html
< HTTP/2 200
< server: wordpress
< x-fragment: title https://site.com/title.html, heading https://site.com/heading.html
< ...


<!DOCTYPE HTML>
<html>
<head>
  <title>
    <!-- fragment:title
    Fallback title
    -->
  </title>
</head>
<body>
<!-- fragment:heading -->
<p>Some content</p>
</body>
</html>
```

* The `title.html` response is just one line `Hello from fragment title`
* `heading.html` contains some more HTML

    ```html
    <h1>This renders a headline</h1>
    ```

The final response should have the fragments resolved and replace with the content from the different prefetches.

```html
<!DOCTYPE HTML>
<html>
<head>
  <title>
    Hello from fragment title
  </title>
</head>
<body>
<h1>This renders a headline</h1>
<p>Some content</p>
</body>
</html>
```

In case, one fragment does not respond timely, is down or could not be found, The fragments resolve
to their fallback. That is just the content of the HTML-comment.

## Cloudflare Workers

This is the forefront (pun intended) of amazing cloud services. Their latest feature: Edge Workers, really
spiked my interest.

We were in the process of examining the ESI space for potential solutions.
And there are not many. So we were already planning to build our own caching layer, that would be
capable of handling includes and fallbacks.

But now, with the power of running a Service Worker API on the edge, we might have just found the perfect solution
for our limited ESI-needs.

### Worker code

Here is what I wrote for Titel Media: https://gist.github.com/Overbryd/c070bb1fa769609d404f648cd506340f

Let me break it down for you here.

1. A client request comes in, the edge worker is picking it up, and passing it to the origin.

    ```js
    addEventListener('fetch', event => {
      event.respondWith(main(event.request))
    })

    async function main(request) {
      // forward the request to the origin (Wordpress)
      const response = await fetch(request)
      // ...
    ```

2. We awaited the response, and we can now check its headers

    ```js
      // ...
      const fragments = prefetchFragments(response.headers)
      // ...
    ```

3. The origin response headers are examined for any values of `X-Fragments`

    ```js
    function prefetchFragments(headers) {
      const header = headers.get('X-Fragments')
      if (header === null) return {}

      const fragments = {}
      const values = header.split(',')
      const safeTimeout = 10000 / values.length

      values.forEach((entry) => {
        const [key, url] = entry.trim().split(' ')
        const request = new Request(url)
        const timeout = new Promise((resolve, reject) => {
          const wait = setTimeout(() => {
            clearTimeout(wait)
            reject()
          }, safeTimeout)
        })

        fragments[key] = Promise.race([
          fetch(request),
          timeout
        ])
      })

      return fragments
    }
    ```

    * If there are fragments to prefetch, those requests are started and stored in a dictionary
      to their respective labels.

    * Each request shares a portion of the global timeout of 10 seconds. A request is later considered to have failed,
      if it did not respond timely.

4. After a few checks on content type and so on, this part is a crucial performance benefit: Streaming the response.

    ```js
        // ...
        const { readable, writable } = new TransformStream()
        transformBody(response.body, writable, fragments)
        // ...
    ```

5. `transformBody` reads the origin response line by line, and searches for fragments.

    ```js
      // ...
      // initialise the parser state
      let state = {writer: writer, fragments: fragments}
      let fun = parse
      let lastLine = ""

      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        const buffer = encoding.decode(value, {stream: !done})
        const lines = (lastLine + buffer).split("\n")

        /* This loop is basically a parse-tree keeping state between each line.
         *
         * But most important, is to not include the last line.
         * The response chunks, might be cut-off just in the middle of a line,
         * and thus not representing a full line that can be reasoned about.
         *
         * Therefore we keep the last line, and concatenate it with the next lines.
         */
        let i = 0;
        const length = lines.length - 1;
        for (; i < length; i++) {
          const line = lines[i]
          const resp = await fun(state, line)
          let [nextFun, newState] = resp
          fun = nextFun
          state = newState
        }
        lastLine = lines[length] || ""
      }

      // ...
    ```

    * If a fragment is found, the worker tries to replace it with the contents of the respective prefetched request.

    * If not, either the fragments fallback-content is returned, or it is simply removed from the output.

## Recap

The article shows the power of running code on the http-edge. With the power of V8 at your fingertips,
you can really build great services right in front of your content delivery.

Edge side includes, if narrowed down to a small feature set, are simple to implement and can even be
safely controlled with timeouts.

My client, Titel Media financed the work on this worker. Stop by at https://www.highsnobiety.com/.

Also, I want to thank the folk from Cloudflare, Harris Hancock and Matthew Prince for their outstanding support,
while developing this worker.

Always Remember: _"Web development is the art of finding the most complex way to concatenate strings."_

Leave a message, or subscribe if you liked this post. I am curious what you think about this solution.

