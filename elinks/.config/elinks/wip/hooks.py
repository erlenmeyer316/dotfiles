import elinks
import hooks
import rules
from bs4 import BeautifulSoup
from importlib import reload

def pre_format_html_hook(url, html):
    # No need to restart elinks to test your rules
    reload(rules)

    if not url.startswith("http"):
        return html

    soup = BeautifulSoup(html, 'html.parser')

    # Bookend the body in hr tags to make it clear where the primary content is
    if body := soup.find_all("body"):
        body[0].insert(0, soup.new_tag("hr"))
        body[0].append(soup.new_tag("hr"))

    # Purge all unseantic stuff. My CSS, my rules.
    [e.decompose() for e in soup.find_all("template")]
    [e.decompose() for e in soup.find_all("style")]
    [e.decompose() for e in soup.find_all("script")]
    for e in soup.descendants:
        try:
            del e["style"]
        except:
            pass

    # I only like some semantic links
    allowed_links = {"next", "prev", "license", "alternate", "author", "canonical", "privacy-policy", "terms-of-service" }
    disallowed_links = { "icons" }
    for e in soup.find_all("link"):
        if "rel" in e.attrs and allowed_links & set(e["rel"]) and not (disallowed_links & set(e["rel"])):
            continue
        e.name = "nolink"

    # Textareas are meant to be big
    for e in soup.find_all("textarea"):
        e["rows"] = 5
        e["cols"] = 80

    # Tables should look like tables with clear borders
    for e in soup.find_all("table"):
        e["border"] = 1
        e["frame"] = "box"

    # Very often websites have huge navigation lists or similar
    # This takes most lists and renders them inline. It's mostly an improvement.
    for e in soup.select("li"):
        e_strings = set(e.strings)
        a_strings = set()
        for a in e.find_all("a"):
            a_strings.update(a.strings)
        if e_strings == a_strings:
            e.name = "span"
            e.insert(0, soup.new_string(" | "))
   
    return str(soup)





def pre_format_html_hook_system(url, html):
    reload(devtools)
    html = devtools.modifier(url, html)
    html = devtools.replacer(url, html)
    return html


