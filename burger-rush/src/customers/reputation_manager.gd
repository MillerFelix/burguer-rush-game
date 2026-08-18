class_name ReputationManager
extends Node

# =============================================================================
# BURGER RUSH - GERENCIADOR CENTRAL DE AVALIAÇÕES E REPUTAÇÃO DO RESTAURANTE
# =============================================================================

signal review_added(review: CustomerReview)
signal reputation_updated(new_rating: float)

static var instance: ReputationManager = null

const MAX_FEED_REVIEWS: int = 60
const MAX_HISTORY_REVIEWS: int = 300

var reviews: Array[CustomerReview] = []
var total_stars: float = 0.0

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	instance = self

static func get_instance() -> ReputationManager:
	if not instance:
		var ml = Engine.get_main_loop()
		if ml and ml is SceneTree:
			var tree = ml as SceneTree
			if tree.root:
				instance = tree.root.find_child("ReputationManager", true, false)
	return instance

func add_review(review: CustomerReview) -> void:
	if not review:
		return

	reviews.append(review)
	total_stars += review.stars

	# Reciclagem de memória do histórico estatístico se ultrapassar limite máximo
	if reviews.size() > MAX_HISTORY_REVIEWS:
		var removed = reviews.pop_front()
		if removed:
			total_stars -= removed.stars

	var new_avg = get_average_rating()
	review_added.emit(review)
	reputation_updated.emit(new_avg)

func submit_delivery_review(order, is_correct: bool, prep_time: float, wait_window_time: float, clock_day: int = 1, clock_time: String = "12:00") -> CustomerReview:
	var exp = CustomerExperience.new(order.id if order else randi(), "Delivery", 100.0, "DELIVERY")
	exp.delivery_prep_time = prep_time
	exp.delivery_window_wait_time = wait_window_time
	exp.order_correct = is_correct
	exp.food_quality = 1.0 if is_correct else 0.2

	if order and order.items.size() > 0:
		var first_item = order.items[0]
		exp.primary_product_id = first_item.get("product_id", first_item.get("recipe_id", "burger_classic"))
		exp.charged_price = first_item.get("unit_price", order.total_price)
		var item_names: Array[String] = []
		for it in order.items:
			item_names.append("%dx %s" % [it.get("quantity", 1), it.get("product_name", "Item")])
		exp.order_summary = ", ".join(item_names)

	var rev = exp.generate_review(clock_day, clock_time)
	add_review(rev)
	return rev

func get_average_rating() -> float:
	if reviews.is_empty():
		return 5.0
	return clampf(snappedf(total_stars / float(reviews.size()), 0.1), 1.0, 5.0)

func get_stars_string() -> String:
	var avg = get_average_rating()
	var filled = int(clamp(round(avg), 1, 5))
	var s = ""
	for i in range(5):
		s += "★" if i < filled else "☆"
	return s

func get_reputation_tier_name() -> String:
	var avg = get_average_rating()
	if avg >= 4.8: return "Excepcional"
	elif avg >= 4.5: return "Excelente"
	elif avg >= 4.0: return "Muito Bom"
	elif avg >= 3.5: return "Bom"
	elif avg >= 3.0: return "Regular"
	elif avg >= 2.0: return "Instável"
	else: return "Crítico"

func get_reputation_color() -> Color:
	var avg = get_average_rating()
	if avg >= 4.5: return Color(0.25, 0.85, 0.45, 1.0) # Verde vibrante
	elif avg >= 3.8: return Color(1.0, 0.80, 0.20, 1.0) # Dourado
	elif avg >= 3.0: return Color(0.95, 0.55, 0.20, 1.0) # Laranja
	else: return Color(0.95, 0.30, 0.30, 1.0) # Vermelho

func get_reviews() -> Array[CustomerReview]:
	return reviews

func get_visible_feed() -> Array[CustomerReview]:
	var feed: Array[CustomerReview] = []
	var start_idx = maxi(0, reviews.size() - MAX_FEED_REVIEWS)
	for i in range(reviews.size() - 1, start_idx - 1, -1):
		feed.append(reviews[i])
	return feed

func get_filtered_feed(filter_category: String = "ALL") -> Array[CustomerReview]:
	var all_feed = get_visible_feed()
	if filter_category == "ALL":
		return all_feed

	var filtered: Array[CustomerReview] = []
	for r in all_feed:
		match filter_category:
			"DINE_IN":
				if r.channel_type == "DINE_IN": filtered.append(r)
			"DRIVE_THRU":
				if r.channel_type == "DRIVE_THRU": filtered.append(r)
			"DELIVERY":
				if r.channel_type == "DELIVERY": filtered.append(r)
			"5_STARS":
				if r.stars >= 4.8: filtered.append(r)
			"COMPLAINTS":
				if r.stars <= 3.0 or r.abandoned or "Demora" in r.tags or "Pedido Incorreto" in r.tags or "Preço Alto" in r.tags or "Restaurante Quente" in r.tags:
					filtered.append(r)
			_:
				filtered.append(r)
	return filtered

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

func get_rating_percentages() -> Dictionary:
	var dist = get_rating_distribution()
	var total = float(maxi(1, reviews.size()))
	var pcts = {}
	for s in range(1, 6):
		pcts[s] = (float(dist[s]) / total) * 100.0
	return pcts

func get_channel_breakdown() -> Dictionary:
	var res = { "DINE_IN": 0, "DRIVE_THRU": 0, "DELIVERY": 0 }
	for r in reviews:
		if res.has(r.channel_type):
			res[r.channel_type] += 1
		else:
			res["DINE_IN"] += 1
	return res

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
