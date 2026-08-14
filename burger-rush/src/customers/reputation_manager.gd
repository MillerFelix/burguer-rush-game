class_name ReputationManager
extends Node

signal review_added(review: CustomerReview)

static var instance: ReputationManager = null

var reviews: Array[CustomerReview] = []
var total_stars: float = 0.0

func _enter_tree() -> void:
	instance = self

static func get_instance() -> ReputationManager:
	return instance

func add_review(review: CustomerReview) -> void:
	reviews.append(review)
	total_stars += review.stars
	review_added.emit(review)

func get_average_rating() -> float:
	if reviews.is_empty():
		return 5.0
	return total_stars / float(reviews.size())

func get_stars_string() -> String:
	var avg = get_average_rating()
	var filled = int(round(avg))
	var s = ""
	for i in range(5):
		s += "★" if i < filled else "☆"
	return s

func get_reviews() -> Array[CustomerReview]:
	return reviews

func get_latest_review() -> CustomerReview:
	if reviews.is_empty():
		return null
	return reviews[reviews.size() - 1]

func clear_all() -> void:
	reviews.clear()
	total_stars = 0.0
