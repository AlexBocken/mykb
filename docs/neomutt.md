# Neomutt

## Markdown to HTML rendering
To write more normie-friendly emails, non-plain-text emails are probably better.
For this, a conversion from Markdown to HTML with Mathjax support seems best.
It supports all the bells and whistles of markdown (images, links, code, italics, bold) as well as mathemtical formulas in LaTex notation using Mathjax.

### Configuration

The conversion is done via pandoc using templates.
Ensure `pandoc` is installed. (`which pandoc || sudo pacman -S pandoc`)

Add to your muttrc (either in `~/.mutt/muttrc` or `~/.config/mutt/muttrc`. From now on assuming `~/.config/mutt` as config folder)

```
macro compose m \
"<enter-command>set pipe_decode<enter>\
<pipe-message>pandoc -f gfm -t plain -o /tmp/msg.txt<enter>\
<pipe-message>pandoc -s --self-contained -o /tmp/msg.html --resource-path ~/.config/mutt/templates/ --template email<enter>\
<enter-command>unset pipe_decode<enter>\
<attach-file>/tmp/msg.txt<enter>\
<attach-file>/tmp/msg.html<enter>\
<tag-entry><previous-entry><tag-entry><group-alternatives>" \
"Convert markdown to HTML5 and plaintext alternative content types"
```

Create a folder called `templates`: `mkdir -p ~/.config/mutt/templates`
and create a file called `email.html` in this folder with the following content:
```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="$lang$" xml:lang="$lang$"$if(dir)$ dir="$dir$"$endif$>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes" />
  <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
  <script type="text/javascript" id="MathJax-script" async
    src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js">
  </script>
  <style>
    $styles.html()$
  </style>
$for(css)$
  <link rel="stylesheet" href="$css$" />
$endfor$
  <!--[if lt IE 9]>
    <script src="//cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.3/html5shiv-printshiv.min.js"></script>
  <![endif]-->
$for(header-includes)$
  $header-includes$
$endfor$
</head>
<body>
  $body$
  $for(include-after)$
  $include-after$
  $endfor$
</body>
</html>
```

### Usage

To use this, write your email as usual and afterwards, press `m` on the created file in neomutt.
This will generate a combined file for plaintext fallback in case of unsupported HTML rendering.

For now, also delete the still present plaintext file with `D`.
Your email should now be ready to be sent.

For writing formulas, just use latex syntax in the normal `$` delimiters.
Be careful on inline formulas, here a whitespace between the leading `$` and the formula breaks the rendering!

## File Size

Since Mathjax is creating a binary for the rendering of the math syntax which is embedded in the html, the file sizes are usually around 1 MB.
This is not necessary when no LaTeX syntax is used.
Create a second macro for which you use a different template, that excludes the mathjax script.
This way you can create smaller emails with pure markdown syntax and when necessary can send mathematical formulas, resulting in larger mails.

For this add the following to the muttrc:
```
macro compose l \
"<enter-command>set pipe_decode<enter>\
<pipe-message>pandoc -f gfm -t plain -o /tmp/msg.txt<enter>\
<pipe-message>pandoc -s --self-contained -o /tmp/msg.html --resource-path ~/.config/mutt/templates/ --template email_pure<enter>\
<enter-command>unset pipe_decode<enter>\
<attach-file>/tmp/msg.txt<enter>\
<attach-file>/tmp/msg.html<enter>\
<tag-entry><previous-entry><tag-entry><group-alternatives>" \
"Convert markdown to HTML5 and plaintext alternative content types"
```

Further create a new file called `email_pure.html` in `mutt/templates` with the following content:
```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="$lang$" xml:lang="$lang$"$if(dir)$ dir="$dir$"$endif$>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes" />
  <style>
    $styles.html()$
  </style>
$for(css)$
  <link rel="stylesheet" href="$css$" />
$endfor$
  <!--[if lt IE 9]>
    <script src="//cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.3/html5shiv-printshiv.min.js"></script>
  <![endif]-->
$for(header-includes)$
  $header-includes$
$endfor$
</head>
<body>
  $body$
  $for(include-after)$
  $include-after$
  $endfor$
</body>
</html>
```



TODO: delete plaintext attachment after HTML creation
TODO: remove `tmp` files after sending
