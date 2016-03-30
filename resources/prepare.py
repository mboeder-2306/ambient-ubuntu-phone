import os, json, subprocess, tempfile, shutil, re

_slugify_strip_re = re.compile(r'[^\w\s-]')
_slugify_hyphenate_re = re.compile(r'[-\s]+')
def slugify(value):
    """
    Normalizes string, converts to lowercase, removes non-alpha characters,
    and converts spaces to hyphens.
    
    From Django's "django/template/defaultfilters.py".
    """
    import unicodedata
    if not isinstance(value, unicode):
        value = unicode(value)
    value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore')
    value = unicode(_slugify_strip_re.sub('', value).strip().lower())
    return _slugify_hyphenate_re.sub('-', value)

def process_image(imgin, imgout, width, height):
    cmd = ["convert", imgin, 
        "-resize", "%sx%s^" % (width, height),
        "-gravity", "Center", "-crop", "%sx%s+0+0" % (width, height),
        "+repage",
        imgout]
    #print " ".join(cmd)
    subprocess.call(cmd)

def process_sound(sndin, sndout):
    cmd = ["oggenc", "-b", "64", "--downmix", "--resample", "22050", sndin, "-o", sndout]
    #print " ".join(cmd)
    subprocess.call(cmd)
    cmd = ["ogginfo", sndout]
    out = subprocess.check_output(cmd)
    length = [x for x in out.split("\n") if "Playback length" in x]
    if len(length) != 1:
        print "Error finding OGG length"
        return 600
    m = re.search("Playback length: ([0-9]+)m:([0-9.]+)s", length[0])
    print "GOT M", m, m.groups()
    if not m:
        print "Error parsing OGG length (in line %r)" % length[0]
        return 600
    return int(m.groups()[0]) * 60 + int(float(m.groups()[1]))

def process(j, container, tempdir):
    fp = open(j)
    data = json.load(fp)
    fp.close()
    print "Processing", data["title"]
    imgfile = os.path.join(container, data["image"]["filename"])
    sndfile = os.path.join(container, data["audio"]["filename"])
    slug = slugify(data["title"])
    imglbout = slug + ".jpg"
    imglboutfile = os.path.join(tempdir, imglbout)
    process_image(imgfile, imglboutfile, 1024, 1024)
    sndout = slug + ".ogg"
    sndoutfile = os.path.join(tempdir, sndout)
    length = process_sound(sndfile, sndoutfile)
    return {
        "title": data["title"],
        "image_letterbox_filename": imglbout,
        "image_credit_name": data["image"]["credit"]["name"],
        "image_credit_url": data["image"]["credit"]["url"],
        "sound_filename": sndout,
        "sound_credit_name": data["audio"]["credit"]["name"],
        "sound_credit_url": data["audio"]["credit"]["url"],
        "sound_length_seconds": length
    }

def main():
    d = os.path.abspath(os.path.dirname(__file__))
    jsons = [os.path.join(d, x) for x in os.listdir(d) if x.endswith(".json")]
    groups = []
    td = tempfile.mkdtemp()
    for j in jsons:
        groups.append(process(j, d, td))
    app = os.path.join(d, "..", "app")
    res = os.path.join(app, "resources")
    try:
        shutil.rmtree(res)
    except:
        pass
    shutil.copytree(td, res)
    fp = open(os.path.join(app, "resources.js"), mode="w")
    fp.write("var RES=")
    fp.write(json.dumps(groups, indent=2))
    fp.write(";")
    fp.close()
    shutil.rmtree(td)

if __name__ == "__main__":
    main()