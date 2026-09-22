# Myers' Diff Algorithm implementation
# Based on "An O(ND) Difference Algorithm and Its Variations" by Eugene W. Myers
class_name GdDiffTool
extends RefCounted


const DIV_ADD :int = 214
const DIV_SUB :int = 215


class Edit:
	enum Type { EQUAL, INSERT, DELETE }
	var type: Type
	var character: int

	func _init(t: Type, chr: int) -> void:
		type = t
		character = chr


# Main entry point - returns [ldiff, rdiff]
static func string_diff(left: Variant, right: Variant) -> Array[PackedInt32Array]:
	var lb := PackedInt32Array() if left == null else str(left).to_utf32_buffer().to_int32_array()
	var rb := PackedInt32Array() if right == null else str(right).to_utf32_buffer().to_int32_array()

	# Early exit for identical strings
	if lb == rb:
		return [lb.duplicate(), rb.duplicate()]

	var edits := _myers_diff(lb, rb)
	return _edits_to_diff_format(edits)


# Core Myers' algorithm
static func _myers_diff(a: PackedInt32Array, b: PackedInt32Array) -> Array[Edit]:
	var n := a.size()
	var m := b.size()
	var max_d := n + m

	# V array stores the furthest reaching x coordinate for each k-line
	# We need indices from -max_d to max_d, so we offset by max_d
	var v := PackedInt32Array()
	v.resize(2 * max_d + 1)
	v.fill(-1)
	v[max_d + 1] = 0  # k=1 starts at x=0

	var trace := []  # Store V arrays for each d to backtrack later

	# Find the edit distance
	for d in range(0, max_d + 1):
		# Store current V for backtracking
		trace.append(v.duplicate())

		for k in range(-d, d + 1, 2):
			var k_offset := k + max_d

			# Decide whether to move down or right
			var x: int
			if k == -d or (k != d and v[k_offset - 1] < v[k_offset + 1]):
				x = v[k_offset + 1]  # Move down (insert from b)
			else:
				x = v[k_offset - 1] + 1  # Move right (delete from a)

			var y := x - k

			# Follow diagonal as far as possible (matching characters)
			while x < n and y < m and a[x] == b[y]:
				x += 1
				y += 1

			v[k_offset] = x

			# Check if we've reached the end
			if x >= n and y >= m:
				return _backtrack(a, b, trace, d, max_d)

	# Should never reach here for valid inputs
	return []


# Backtrack through the edit graph to build the edit script
static func _backtrack(a: PackedInt32Array, b: PackedInt32Array, trace: Array, d: int, max_d: int) -> Array[Edit]:
	var edits: Array[Edit] = []
	var x := a.size()
	var y := b.size()

	# Walk backwards through each d value
	for depth in range(d, -1, -1):
		var v: PackedInt32Array = trace[depth]
		var k := x - y
		var k_offset := k + max_d

		# Determine previous k
		var prev_k: int
		if k == -depth or (k != depth and v[k_offset - 1] < v[k_offset + 1]):
			prev_k = k + 1
		else:
			prev_k = k - 1

		var prev_k_offset := prev_k + max_d
		var prev_x := v[prev_k_offset]
		var prev_y := prev_x - prev_k

		# Extract diagonal (equal) characters
		while x > prev_x and y > prev_y:
			x -= 1
			y -= 1
			#var char_array := PackedInt32Array([a[x]])
			edits.insert(0, Edit.new(Edit.Type.EQUAL, a[x]))

		# Record the edit operation
		if depth > 0:
			if x == prev_x:
				# Insert from b
				y -= 1
				#var char_array := PackedInt32Array([b[y]])
				edits.insert(0, Edit.new(Edit.Type.INSERT, b[y]))
			else:
				# Delete from a
				x -= 1
				#var char_array := PackedInt32Array([a[x]])
				edits.insert(0, Edit.new(Edit.Type.DELETE, a[x]))

	return edits


# Convert edit script to the DIV_ADD/DIV_SUB format
static func _edits_to_diff_format(edits: Array[Edit]) -> Array[PackedInt32Array]:
	var ldiff := PackedInt32Array()
	var rdiff := PackedInt32Array()

	for edit in edits:
		match edit.type:
			Edit.Type.EQUAL:
				ldiff.append(edit.character)
				rdiff.append(edit.character)
			Edit.Type.INSERT:
				ldiff.append(DIV_ADD)
				ldiff.append(edit.character)
				rdiff.append(DIV_SUB)
				rdiff.append(edit.character)
			Edit.Type.DELETE:
				ldiff.append(DIV_SUB)
				ldiff.append(edit.character)
				rdiff.append(DIV_ADD)
				rdiff.append(edit.character)

	return [ldiff, rdiff]


# prototype
static func longestCommonSubsequence(text1 :String, text2 :String) -> PackedStringArray:
	var text1Words := text1.split(" ")
	var text2Words := text2.split(" ")
	var text1WordCount := text1Words.size()
	var text2WordCount := text2Words.size()
	var solutionMatrix := Array()
	for i in text1WordCount+1:
		var ar := Array()
		for n in text2WordCount+1:
			ar.append(0)
		solutionMatrix.append(ar)

	for i in range(text1WordCount-1, 0, -1):
		for j in range(text2WordCount-1, 0, -1):
			if text1Words[i] == text2Words[j]:
				solutionMatrix[i][j] = solutionMatrix[i + 1][j + 1] + 1;
			else:
				solutionMatrix[i][j] = max(solutionMatrix[i + 1][j], solutionMatrix[i][j + 1]);

	var i := 0
	var j := 0
	var lcsResultList := PackedStringArray();
	while (i < text1WordCount && j < text2WordCount):
		if text1Words[i] == text2Words[j]:
			@warning_ignore("return_value_discarded")
			lcsResultList.append(text2Words[j])
			i += 1
			j += 1
		else: if (solutionMatrix[i + 1][j] >= solutionMatrix[i][j + 1]):
			i += 1
		else:
			j += 1
	return lcsResultList


static func markTextDifferences(text1 :String, text2 :String, lcsList :PackedStringArray, insertColor :Color, deleteColor:Color) -> String:
	var stringBuffer := ""
	if text1 == null and lcsList == null:
		return stringBuffer

	var text1Words := text1.split(" ")
	var text2Words := text2.split(" ")
	var i := 0
	var j := 0
	var word1LastIndex := 0
	var word2LastIndex := 0
	for k in lcsList.size():
		while i < text1Words.size() and j < text2Words.size():
			if text1Words[i] == lcsList[k] and text2Words[j] == lcsList[k]:
				stringBuffer += "<SPAN>" + lcsList[k] + " </SPAN>"
				word1LastIndex = i + 1
				word2LastIndex = j + 1
				i = text1Words.size()
				j = text2Words.size()

			else: if text1Words[i] != lcsList[k]:
				while i < text1Words.size() and text1Words[i] != lcsList[k]:
					stringBuffer += "<SPAN style='BACKGROUND-COLOR:" + deleteColor.to_html() + "'>" + text1Words[i] + " </SPAN>"
					i += 1
			else: if text2Words[j] != lcsList[k]:
				while j < text2Words.size() and text2Words[j] != lcsList[k]:
					stringBuffer += "<SPAN style='BACKGROUND-COLOR:" + insertColor.to_html() + "'>" + text2Words[j] + " </SPAN>"
					j += 1
			i = word1LastIndex
			j = word2LastIndex

			while word1LastIndex < text1Words.size():
				stringBuffer += "<SPAN style='BACKGROUND-COLOR:" + deleteColor.to_html() + "'>" + text1Words[word1LastIndex] + " </SPAN>"
				word1LastIndex += 1
			while word2LastIndex < text2Words.size():
				stringBuffer += "<SPAN style='BACKGROUND-COLOR:" + insertColor.to_html() + "'>" + text2Words[word2LastIndex] + " </SPAN>"
				word2LastIndex += 1
	return stringBuffer
