class_name ReputationManager
extends Node

# Gerenciador Central de Avaliações e Reputação do Restaurante
signal review_added(review: CustomerReview)

static var instance: ReputationManager = null

var reviews: Array[CustomerReview] = []
var total_stars: float = 0.0

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	instance = self

static func get_instance() -> ReputationManager:
	return instance

func add_review(review: CustomerReview) -> void:
	if not review:
		return
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

func get_total_reviews() -> int:
	return reviews.size()

func get_total_abandoned() -> int:
	var count = 0
	for r in reviews:
		if r.abandoned:
			count += 1
	return count

func get_abandon_rate() -> float:
	if reviews.is_empty():
		return 0.0
	return float(get_total_abandoned()) / float(reviews.size())

func get_rating_distribution() -> Dictionary:
	var dist = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }
	for r in reviews:
		var star_int = clampi(int(round(r.stars)), 1, 5)
		dist[star_int] = dist.get(star_int, 0) + 1
	return dist

func get_sentiment_summary() -> Dictionary:
	var positive = 0 # 4 ou 5 estrelas
	var neutral = 0  # 3 estrelas
	var negative = 0 # 1 ou 2 estrelas
	for r in reviews:
		if r.stars >= 3.8:
			positive += 1
		elif r.stars >= 2.8:
			neutral += 1
		else:
			negative += 1
	return {
		"positive": positive,
		"neutral": neutral,
		"negative": negative
	}

func get_today_reviews(day_num: int) -> Array[CustomerReview]:
	var res: Array[CustomerReview] = []
	for r in reviews:
		if r.day == day_num:
			res.append(r)
	return res

func get_latest_review() -> CustomerReview:
	if reviews.is_empty():
		return null
	return reviews[reviews.size() - 1]

func clear_all() -> void:
	reviews.clear()
	total_stars = 0.0
