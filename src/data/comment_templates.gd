## CommentTemplates — externalized Korean comment bodies keyed by template key (ADR-0007).
##
## The evaluation algorithm selects WHICH key per subscore (story 005); the content lives
## here (assets/data/evaluation/comment_templates.tres). GDD §3.1.5 7-key set.
##
## ADR: docs/architecture/adr-0007-submission-evaluation-algorithm.md
## TR:  TR-submission-*
class_name CommentTemplates extends Resource

## template_key → 한국어 본문.
@export var templates: Dictionary = {}
