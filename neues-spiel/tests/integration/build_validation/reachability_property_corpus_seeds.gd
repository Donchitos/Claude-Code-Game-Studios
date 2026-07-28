## Checked-in seed fixture for Build Validation & Navigability story
## build-validation-010 (AC36 reachability property corpus; QA plan
## `production/qa/qa-plan-sprint-9-2026-07-26.md` Content Requirement 3).
##
## **This is a FIXTURE, not gameplay data, and it is NOT generated at test
## time.** Every one of the 100 integers below is a literal, checked-in
## constant -- there is no `range()`/RNG call anywhere in this file that
## computes the list. This satisfies the project's "no random seeds in
## tests" testing standard by construction (`.claude/rules/test-standards.md`,
## `.claude/docs/coding-standards.md`): the project's own carve-out for
## "boundary value tests where the exact number IS the point" applies
## per-seed here -- each checked-in seed IS the point, probing a specific
## corner of [method VoxelWorldGrid.generate_terrain]'s deterministic noise
## behavior plus [ReachabilityPropertyCorpusTest]'s own deterministic
## wall/floor/roof solid-fill layer, at that seed's own derived density and
## sampled pairs.
##
## Zero-flake policy (QA plan Content Requirement 3): because every seed
## here is a fixed, checked-in integer fed only into deterministic pure
## functions ([method VoxelWorldGrid._pure_terrain_height]/[method
## VoxelWorldGrid._pure_terrain_noise] under [method
## VoxelWorldGrid.generate_terrain], plus [RandomNumberGenerator]'s own
## deterministic-given-a-fixed-seed stream), the SAME seed list must produce
## the IDENTICAL 5,000 verdicts on every run, on every machine. A run that
## diverges from a prior run over this SAME list is never explained by
## "flakiness" -- there is no live randomness anywhere in the pipeline this
## list feeds -- so any such divergence is itself a new nondeterminism bug,
## not noise to be retried away (see
## [ReachabilityPropertyCorpusTest]'s own doc comment for the full policy).
##
## Fixture integrity (this file's own QA Test Case): exactly 100 entries,
## verified by [ReachabilityPropertyCorpusTest.test_seed_list_fixture_contains_exactly_100_checked_in_seeds].
## Never edit this list to "fix" a corpus failure -- a genuine seed/pair
## disagreement is resolved by fixing the diverging implementation (with its
## own dedicated single-seed regression fixture, per that test's doc
## comment), never by removing or replacing the seed that found it.
class_name BuildValidationReachabilityCorpusSeeds
extends RefCounted

## 100 checked-in seeds (literal, not computed) -- see class doc comment.
const SEEDS: Array[int] = [
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
	11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
	21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
	31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
	51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
	61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
	71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
	81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
	91, 92, 93, 94, 95, 96, 97, 98, 99, 100,
]
