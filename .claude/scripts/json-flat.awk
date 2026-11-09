# json-flat.awk — prints each scalar of a JSON file as one TSV line:
#   <top key> TAB <the rest of the path, joined by /, or empty> TAB <value>
# so `"scripts": { "dev": "vite" }` prints `scripts	dev	vite` and
# `"workspaces": ["packages/*"]` prints `workspaces	0	packages/*`. An array
# index is its number from 0. Strings are unescaped for \" \\ \/ \t \n (a tab or
# newline in a value becomes a space); \uXXXX is left as written. true, false,
# null and numbers print as written. A key holding / is printed as it is, so the
# rest-of-path column is for reading, not for splitting.
#
# Built for package.json (web-detect.sh): a file that is not one JSON object
# prints what it read before the first error, then `!error<TAB><TAB><where>`.
#
# Usage: awk -f json-flat.awk FILE
# BWK awk safe (no gawk extensions).

{ buf = buf $0 "\n" }

END {
  n = length(buf); i = 1; depth = 0; err = ""
  skipws()
  if (substr(buf, i, 1) != "{") { print "!error\t\tnot a JSON object"; exit }
  value("")
  if (err != "") print "!error\t\t" err
}

function skipws(   c) {
  while (i <= n) {
    c = substr(buf, i, 1)
    if (c != " " && c != "\t" && c != "\n" && c != "\r") return
    i++
  }
}

function emit(path, v,   top, rest, p) {
  p = index(path, SUBSEP)
  if (p == 0) { top = path; rest = "" }
  else {
    top = substr(path, 1, p - 1); rest = substr(path, p + 1)
    gsub(SUBSEP, "/", rest)
  }
  print top "\t" rest "\t" v
}

function join(path, k) { return path == "" ? k : path SUBSEP k }

# value(path) — reads one value at i; returns 1 on success.
function value(path,   c, k, idx, s) {
  if (err != "") return 0
  skipws(); c = substr(buf, i, 1)
  if (c == "{") {
    i++; skipws()
    if (substr(buf, i, 1) == "}") { i++; return 1 }
    while (1) {
      skipws()
      if (substr(buf, i, 1) != "\"") { err = "expected a key at byte " i; return 0 }
      k = str()
      skipws()
      if (substr(buf, i, 1) != ":") { err = "expected : at byte " i; return 0 }
      i++
      if (!value(join(path, k))) return 0
      skipws(); c = substr(buf, i, 1)
      if (c == ",") { i++; continue }
      if (c == "}") { i++; return 1 }
      err = "expected , or } at byte " i; return 0
    }
  }
  if (c == "[") {
    i++; skipws(); idx = 0
    if (substr(buf, i, 1) == "]") { i++; return 1 }
    while (1) {
      if (!value(join(path, idx))) return 0
      idx++
      skipws(); c = substr(buf, i, 1)
      if (c == ",") { i++; continue }
      if (c == "]") { i++; return 1 }
      err = "expected , or ] at byte " i; return 0
    }
  }
  if (c == "\"") { s = str(); if (err != "") return 0; emit(path, s); return 1 }
  # true, false, null or a number: up to the next delimiter.
  s = ""
  while (i <= n) {
    c = substr(buf, i, 1)
    if (c == "," || c == "}" || c == "]" || c == " " || c == "\t" || c == "\n" || c == "\r") break
    s = s c; i++
  }
  if (s == "") { err = "expected a value at byte " i; return 0 }
  emit(path, s); return 1
}

# str() — reads a string at i (on its opening quote); returns its text.
function str(   c, s, e) {
  i++; s = ""
  while (i <= n) {
    c = substr(buf, i, 1)
    if (c == "\"") { i++; return s }
    if (c == "\\") {
      e = substr(buf, i + 1, 1); i += 2
      if (e == "n" || e == "t" || e == "r") s = s " "
      else if (e == "u") s = s "\\u"
      else s = s e
      continue
    }
    if (c == "\n") c = " "
    s = s c; i++
  }
  err = "unterminated string"; return s
}
