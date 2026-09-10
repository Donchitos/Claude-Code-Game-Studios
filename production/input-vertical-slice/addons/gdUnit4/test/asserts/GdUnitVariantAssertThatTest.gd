extends GdUnitTestSuite


func test_is_equal_success() -> void:
	assert_that(3 as Variant).is_equal(3)
	assert_that(3.14 as Variant).is_equal(3.14)
	assert_that("3" as Variant).is_equal("3")
	assert_that(true as Variant).is_equal(true)
	assert_that(Vector2.ONE as Variant).is_equal(Vector2.ONE)
	assert_that({a=1, b=2} as Variant).is_equal({a=1, b=2})
	assert_that([1,2,3] as Variant).is_equal([1,2,3])
	assert_that(RefCounted.new() as Variant).is_equal(RefCounted.new())


func test_is_equal_fail() -> void:
	# bool vs int
	assert_failure(func()->void:
		assert_that(true as Variant).is_equal(1))\
		.is_failed()

	# bool vs string
	assert_failure(func()->void:
		assert_that(true as Variant).is_equal("true"))\
		.is_failed()

	# int vs string
	assert_failure(func()->void:
			assert_that(3 as Variant).is_equal("3"))\
		.is_failed()

	# float vs string
	assert_failure(func()->void:
			assert_that(3.14 as Variant).is_equal("3.14"))\
		.is_failed()

	# string vs int
	assert_failure(func()->void:
			assert_that("3" as Variant).is_equal(3))\
		.is_failed()

	# string vs float
	assert_failure(func()->void:
		assert_that("3.14" as Variant).is_equal(3.14))\
		.is_failed()

	# vector vs string
	assert_failure(func()->void:
		assert_that(Vector2.ONE as Variant).is_equal("ONE"))\
		.is_failed()

	# dictionary vs string
	assert_failure(func()->void:
		assert_that({a=1, b=2} as Variant).is_equal("FOO"))\
		.is_failed()

	# array vs string
	assert_failure(func()->void:
		assert_that([1,2,3] as Variant).is_equal("FOO"))\
		.is_failed()

	# object vs string
	assert_failure(func()->void:
		assert_that(RefCounted.new() as Variant).is_equal("FOO"))\
		.is_failed()


func test_is_not_equal_success() -> void:
	assert_that(3 as Variant).is_not_equal(4)
	assert_that(3.14 as Variant).is_not_equal(3.15)
	assert_that("3" as Variant).is_not_equal("33")
	assert_that(true as Variant).is_not_equal(false)
	assert_that(Vector2.ONE as Variant).is_not_equal(Vector2.UP)
	assert_that({a=1, b=2} as Variant).is_not_equal({a=1, b=3})
	assert_that([1,2,3] as Variant).is_not_equal([1,2,4])
	assert_that(RefCounted.new() as Variant).is_not_equal(null)


func test_is_not_equal_fail() -> void:
	# bool vs int
	assert_failure(func()->void:
		assert_that(true as Variant).is_not_equal(true)
		)\
		.is_failed()


	assert_failure(func()->void:
			assert_that(3 as Variant).is_not_equal(3))\
		.is_failed()

	assert_failure(func()->void:
			assert_that(3.14 as Variant).is_not_equal(3.14))\
		.is_failed()

	assert_failure(func()->void:
			assert_that("3" as Variant).is_not_equal("3"))\
		.is_failed()

	# vector vs string
	assert_failure(func()->void:
		assert_that(Vector2.ONE as Variant).is_not_equal(Vector2.ONE))\
		.is_failed()

	# dictionary vs string
	assert_failure(func()->void:
		assert_that({a=1, b=2} as Variant).is_not_equal({a=1, b=2}))\
		.is_failed()

	# array vs string
	assert_failure(func()->void:
		assert_that([1,2,3] as Variant).is_not_equal([1,2,3]))\
		.is_failed()

	# object vs string
	assert_failure(func()->void:
		assert_that(RefCounted.new() as Variant).is_not_equal(RefCounted.new()))\
		.is_failed()
