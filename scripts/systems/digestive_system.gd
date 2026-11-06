class_name DigestiveSystem
extends SimSystem
## The digestive system: a baby carrot travels from the mouth to the anus.
## Background: art/digestive_background.png, rendered from art/source/digestive-system.svg
## (879.819 x 978.418) scaled by SVG_SCALE and centred with SVG_OFFSET.
## The path and station points were traced from the SVG's "food-path".

const SVG_SCALE: float = 0.7358818010298257
const SVG_OFFSET: Vector2 = Vector2(16.279, 0.0)

# Station indices
const MOUTH: int = 0
const ESOPHAGUS: int = 1
const STOMACH: int = 2
const SMALL_INTESTINE: int = 3
const LARGE_INTESTINE: int = 4
const RECTUM: int = 5


func _init() -> void:
	title = "Journey of a Baby Carrot"
	traveller_name = "the carrot"
	start_label = "Ready to eat"
	background_path = "res://art/digestive_background.png"
	background_rect = Rect2(SVG_OFFSET, Vector2(879.819, 978.418) * SVG_SCALE)
	start_pos = Vector2(265.7, 138.2)
	is_loop = false
	has_match_quiz = true
	min_travel_time = 1.0
	max_travel_time = 6.0
	_build_organs()
	_build_stations()
	_build_segments()
	# Where each leg crosses into the next organ's shape. Measured by testing every path point
	# against the SVG's named shapes (_Path_OralCavity, _Path_Esophagus, StomachWalls,
	# SmallIntestine, UpperColon, LowerColon = the purple rectum). Re-measure if the art changes.
	segment_switch_t = [0.375, 0.18, 0.68, 0.13, 0.63, 0.734]


func _box(x0: float, y0: float, x1: float, y1: float) -> Rect2:
	return SimSystem.svg_rect(x0, y0, x1, y1, SVG_SCALE, SVG_OFFSET)


func _build_organs() -> void:
	organs = {
		"teeth": {
			"name": "Teeth", "box": _box(94.229, 129.042, 309.228, 210.282),
			"function": "Break food into smaller pieces (chewing)",
			"hint": "",
		},
		"tongue": {
			"name": "Tongue", "box": _box(72.483, 223.207, 287.482, 304.447),
			"function": "Mixes food with saliva",
			"hint": "",
		},
		"salivary": {
			"name": "Salivary Glands", "box": _box(597.671, 96.833, 812.671, 178.073),
			"function": "Make saliva, which starts digesting carbohydrates",
			"hint": "Food doesn't go into the salivary glands. They pour saliva into the mouth.",
		},
		"esophagus": {
			"name": "Esophagus", "box": _box(600.133, 193.665, 873.806, 293.163),
			"function": "Pushes food from the mouth to the stomach",
			"hint": "",
		},
		"liver": {
			"name": "Liver", "box": _box(29.811, 388.969, 244.81, 470.209),
			"function": "Makes bile",
			"hint": "Food never goes through the liver. It makes bile, which is sent to the small intestine.",
		},
		"gallbladder": {
			"name": "Gallbladder", "box": _box(24.887, 493.186, 239.887, 574.427),
			"function": "Stores bile",
			"hint": "Food doesn't go through the gallbladder. It stores bile and squeezes it into the small intestine.",
		},
		"stomach": {
			"name": "Stomach", "box": _box(637.061, 424.666, 852.06, 550.014),
			"function": "Churns food with acid and enzymes",
			"hint": "",
		},
		"pancreas": {
			"name": "Pancreas", "box": _box(663.32, 591.249, 878.319, 691.158),
			"function": "Makes several digestive enzymes",
			"hint": "Food doesn't pass through the pancreas. It sends digestive enzymes into the small intestine.",
		},
		"small_intestine": {
			"name": "Small Intestine", "box": _box(661.679, 702.031, 876.678, 865.127),
			"function": "Finishes digestion; nutrients pass into the blood",
			"hint": "",
		},
		"large_intestine": {
			"name": "Large Intestine", "box": _box(1.5, 680.695, 269.428, 739.779),
			"function": "Absorbs water from food waste",
			"hint": "",
		},
		"appendix": {
			"name": "Appendix", "box": _box(56.891, 826.353, 271.89, 907.593),
			"function": "No known job in digestion",
			"hint": "The appendix is a small dead-end pouch on the large intestine. Food doesn't travel through it.",
		},
		"rectum": {
			"name": "Rectum & Anus", "box": _box(577.265, 895.678, 792.265, 976.918),
			"function": "Stores waste until it leaves the body",
			"hint": "",
		},
	}
	organ_order = ["teeth", "tongue", "salivary", "esophagus", "liver", "gallbladder", "stomach",
		"pancreas", "small_intestine", "large_intestine", "appendix", "rectum"]
	# No pure red herrings: every non-tract organ has a "?" box on the map, so students must
	# label each one (on its own box) before the carrot can move on. See quiz_helper_groups.
	quiz_distractors = []
	quiz_helper_groups = [
		{
			"before": ESOPHAGUS, "organs": ["salivary"],
			"prompt": "Before you swallow, label the helper organ that works in the mouth. Drag it onto its own box!",
		},
		{
			"before": SMALL_INTESTINE, "organs": ["liver", "gallbladder", "pancreas"],
			"prompt": "Before the carrot moves on, label the 3 helper organs that send juices to the next stop!",
		},
		{
			"before": LARGE_INTESTINE, "organs": ["appendix"],
			"prompt": "Before the waste moves on, label the small dead-end pouch on the next part of the tract!",
		},
	]


func _build_stations() -> void:
	stations = [
		{
			"name": "Mouth", "pos": Vector2(310.8, 125),
			"boxes": ["teeth", "tongue"], "helpers": ["salivary"],
			"digestion": ["mechanical", "chemical"],
			"info": "The teeth chew (masticate) the carrot into smaller and smaller pieces: mechanical digestion. The tongue mixes the pieces with saliva from the salivary glands. Saliva contains an enzyme, salivary amylase, that starts breaking down carbohydrates: chemical digestion.",
			"breaking_down": "Carbohydrates (starch) into shorter chains. Still too big to absorb.",
		},
		{
			"name": "Esophagus", "pos": Vector2(365, 256.8),
			"boxes": ["esophagus"], "helpers": [],
			"digestion": ["mechanical"],
			"info": "You swallow. Waves of muscle contractions, called peristalsis, push the chewed carrot down the esophagus to the stomach.",
			"breaking_down": "Nothing new. The food is only moved along.",
		},
		{
			"name": "Stomach", "pos": Vector2(412.5, 423),
			"boxes": ["stomach"], "helpers": [],
			"digestion": ["mechanical", "chemical"],
			"info": "Stomach muscles churn and squeeze the food (mechanical) and mix it with hydrochloric acid and enzymes (chemical). The enzyme pepsin starts breaking down proteins. The carrot becomes a thick paste.",
			"breaking_down": "Proteins into smaller pieces. Carrots have only a little protein.",
		},
		{
			"name": "Small Intestine", "pos": Vector2(368.3, 548.1),
			"boxes": ["small_intestine"], "helpers": ["pancreas", "liver", "gallbladder"],
			"digestion": ["chemical", "absorption"],
			"info": "Enzymes from the pancreas finish the job: amylase splits carbohydrates into single sugars, trypsin splits proteins into amino acids, and lipase breaks down fats with help from bile (made by the liver, stored in the gallbladder). The nutrients are now small enough to pass into the bloodstream, which carries them to cells all over the body.",
			"breaking_down": "Carbohydrates into sugars, proteins into amino acids, fats into smaller parts.",
		},
		{
			"name": "Large Intestine", "pos": Vector2(298.9, 487.3),
			"boxes": ["large_intestine"], "helpers": [],
			"digestion": ["none"],
			"info": "What is left is mostly fibre the body cannot digest, plus water. The large intestine absorbs the water, so the waste becomes solid. No more digestion happens here.",
			"breaking_down": "Nothing. Water is absorbed from the waste.",
		},
		{
			"name": "Rectum & Anus", "pos": Vector2(350.3, 688.1),
			"boxes": ["rectum"], "helpers": [],
			"digestion": ["none"],
			"info": "Solid waste is stored in the rectum until it leaves the body through the anus. This is called elimination.",
			"breaking_down": "Nothing. The waste leaves the body.",
		},
	]


func _build_segments() -> void:
	segments = [
	PackedVector2Array([Vector2(265.7, 138.2), Vector2(271.2, 136.2), Vector2(276.8, 134.2), Vector2(282.3, 132.2), Vector2(287.9, 130.4), Vector2(293.5, 128.6), Vector2(299.2, 127), Vector2(305, 125.8), Vector2(310.8, 125)]),
	PackedVector2Array([Vector2(310.8, 125), Vector2(316.6, 124.2), Vector2(322.5, 123.7), Vector2(328.4, 123.6), Vector2(334.2, 124.2), Vector2(339.8, 126), Vector2(344.5, 129.4), Vector2(347.2, 134.6), Vector2(349, 140.2), Vector2(350.3, 146), Vector2(351.5, 151.7), Vector2(352.4, 157.6), Vector2(353.3, 163.4), Vector2(354, 169.2), Vector2(354.6, 175.1), Vector2(355.3, 180.9), Vector2(356, 186.8), Vector2(356.8, 192.6), Vector2(357.5, 198.4), Vector2(358.3, 204.3), Vector2(359, 210.1), Vector2(359.8, 216), Vector2(360.5, 221.8), Vector2(361.3, 227.6), Vector2(362, 233.5), Vector2(362.8, 239.3), Vector2(363.5, 245.2), Vector2(364.3, 251), Vector2(365, 256.8)]),
	PackedVector2Array([Vector2(365, 256.8), Vector2(365.8, 262.7), Vector2(366.5, 268.5), Vector2(367.3, 274.4), Vector2(368, 280.2), Vector2(368.8, 286), Vector2(369.5, 291.9), Vector2(370.3, 297.7), Vector2(371, 303.5), Vector2(371.8, 309.4), Vector2(372.5, 315.2), Vector2(373.3, 321.1), Vector2(374, 326.9), Vector2(374.8, 332.7), Vector2(375.5, 338.6), Vector2(376.3, 344.4), Vector2(377, 350.3), Vector2(377.8, 356.1), Vector2(378.5, 361.9), Vector2(379.3, 367.8), Vector2(380, 373.6), Vector2(380.8, 379.5), Vector2(382.1, 385.2), Vector2(387.1, 387.9), Vector2(392.9, 388.9), Vector2(398.7, 389.6), Vector2(404.5, 390.9), Vector2(409.8, 393.4), Vector2(413.7, 397.7), Vector2(415.7, 403.1), Vector2(416.1, 409), Vector2(415.5, 414.8), Vector2(414, 420.5), Vector2(412.5, 423)]),
	PackedVector2Array([Vector2(412.5, 423), Vector2(409, 427.7), Vector2(404.4, 431.3), Vector2(399.2, 433.9), Vector2(393.5, 435.7), Vector2(387.8, 436.8), Vector2(381.9, 437.3), Vector2(376, 437.5), Vector2(370.1, 437.3), Vector2(364.3, 436.9), Vector2(358.4, 436.3), Vector2(352.6, 435.5), Vector2(346.8, 434.6), Vector2(341, 433.5), Vector2(335.2, 432.2), Vector2(329.5, 431.1), Vector2(323.7, 432.1), Vector2(318.8, 435.3), Vector2(314.8, 439.5), Vector2(312.3, 444.9), Vector2(310.9, 450.6), Vector2(310.1, 456.4), Vector2(309.5, 462.3), Vector2(309.3, 468.1), Vector2(309.2, 474), Vector2(309.4, 479.9), Vector2(309.8, 485.8), Vector2(310.5, 491.6), Vector2(311.4, 497.4), Vector2(312.8, 503.2), Vector2(315.1, 508.3), Vector2(316, 509.4), Vector2(321.7, 510.6), Vector2(327.6, 511.3), Vector2(333.4, 511.5), Vector2(339.3, 511.8), Vector2(345.2, 511.3), Vector2(351, 510.4), Vector2(356.7, 509.1), Vector2(362.5, 507.7), Vector2(368.1, 506.2), Vector2(373.8, 504.6), Vector2(379.4, 502.8), Vector2(385, 500.9), Vector2(390.5, 498.8), Vector2(396.1, 497), Vector2(392, 500.9), Vector2(387.3, 504.4), Vector2(382.4, 507.6), Vector2(381.5, 511.7), Vector2(387.2, 513), Vector2(392.9, 511.7), Vector2(398.2, 509), Vector2(403, 505.7), Vector2(407.6, 502.1), Vector2(412.2, 498.3), Vector2(416.8, 494.7), Vector2(422.1, 494.2), Vector2(426.7, 497.8), Vector2(429.1, 503), Vector2(425.3, 507), Vector2(419.7, 508.9), Vector2(414, 510.4), Vector2(408.4, 512.1), Vector2(403.4, 515.1), Vector2(402.7, 520.6), Vector2(405.7, 525.6), Vector2(410.1, 529.4), Vector2(415.8, 530.6), Vector2(420.9, 527.9), Vector2(426.4, 525.9), Vector2(431.1, 528.6), Vector2(431.7, 534.4), Vector2(431.9, 540.3), Vector2(431.7, 546.2), Vector2(430.8, 552), Vector2(428.8, 557.5), Vector2(425.2, 562.2), Vector2(420.8, 566.1), Vector2(416.2, 569.8), Vector2(411.7, 573.6), Vector2(407.8, 577.9), Vector2(405.1, 583.1), Vector2(404.3, 589), Vector2(404, 594.8), Vector2(403.8, 600.7), Vector2(403, 606.5), Vector2(400.7, 612), Vector2(396.9, 616.2), Vector2(391.1, 617.3), Vector2(385.2, 617.1), Vector2(380, 614.7), Vector2(376.8, 609.8), Vector2(374.2, 604.5), Vector2(370.6, 599.9), Vector2(366.6, 595.6), Vector2(362.3, 591.6), Vector2(357.5, 588.2), Vector2(352.1, 585.7), Vector2(346.3, 585.3), Vector2(340.7, 586.9), Vector2(335.1, 588.8), Vector2(329.6, 590.8), Vector2(326.8, 594.6), Vector2(332.3, 596.5), Vector2(338.1, 597.6), Vector2(343.9, 598.2), Vector2(349.7, 599.1), Vector2(354.6, 602.3), Vector2(358.6, 606.6), Vector2(362.7, 610.9), Vector2(365.5, 615.8), Vector2(360.1, 616.3), Vector2(354.4, 614.8), Vector2(348.8, 613), Vector2(343.4, 610.7), Vector2(338.1, 608.1), Vector2(332.8, 605.5), Vector2(327.2, 603.9), Vector2(321.3, 604), Vector2(315.4, 604.6), Vector2(314.4, 607.9), Vector2(319.8, 610.3), Vector2(325.3, 612.4), Vector2(330.8, 614.4), Vector2(336.3, 616.4), Vector2(341.9, 618.4), Vector2(347.4, 620.3), Vector2(353, 622.2), Vector2(358.6, 624.1), Vector2(364.2, 625.8), Vector2(365.1, 629.4), Vector2(360.3, 632.7), Vector2(354.8, 634.7), Vector2(349, 635.5), Vector2(343.1, 635.1), Vector2(337.4, 633.9), Vector2(331.6, 632.5), Vector2(325.9, 631.3), Vector2(320.1, 630), Vector2(314.4, 628.5), Vector2(309, 626.2), Vector2(304.9, 622.1), Vector2(302.4, 616.8), Vector2(300.5, 611.3), Vector2(299.3, 605.5), Vector2(299.7, 599.7), Vector2(304.6, 596.9), Vector2(310.2, 595.1), Vector2(315.1, 592.1), Vector2(318.6, 587.3), Vector2(322.5, 582.9), Vector2(326.7, 578.9), Vector2(331.3, 575.2), Vector2(336.5, 572.3), Vector2(341.9, 570.1), Vector2(347.2, 567.6), Vector2(352.7, 565.5), Vector2(357.3, 567.5), Vector2(355.8, 573.1), Vector2(355.1, 578.7), Vector2(360, 581.6), Vector2(364.9, 584.9), Vector2(369.3, 588.8), Vector2(374.2, 592), Vector2(379, 595.4), Vector2(383.9, 598.7), Vector2(389.1, 601.4), Vector2(394.3, 600), Vector2(396.6, 594.7), Vector2(395.3, 589.1), Vector2(391.1, 585), Vector2(387.8, 580.2), Vector2(387.1, 574.5), Vector2(389.7, 569.2), Vector2(391.3, 563.6), Vector2(392.1, 557.7), Vector2(392.3, 551.9), Vector2(392, 546), Vector2(390.5, 540.3), Vector2(388, 535), Vector2(384.6, 530.2), Vector2(380.4, 526.1), Vector2(375.6, 522.8), Vector2(370.5, 519.8), Vector2(365.4, 516.8), Vector2(360, 514.4), Vector2(354.2, 513.7), Vector2(349, 516.1), Vector2(345.2, 520.5), Vector2(343.3, 526), Vector2(346.6, 530.5), Vector2(352.3, 531.8), Vector2(358.2, 531.8), Vector2(364.1, 531.6), Vector2(369.9, 532.3), Vector2(372.2, 537), Vector2(370, 542.5), Vector2(368.3, 548.1)]),
	PackedVector2Array([Vector2(368.3, 548.1), Vector2(366.8, 553.8), Vector2(362.6, 557.3), Vector2(357, 555.8), Vector2(351.6, 553.3), Vector2(346.2, 551.2), Vector2(340.4, 549.8), Vector2(334.6, 549.1), Vector2(328.8, 548.2), Vector2(323.9, 545.2), Vector2(320.6, 540.3), Vector2(319.6, 534.5), Vector2(321.5, 529), Vector2(324.7, 524.1), Vector2(322.4, 519.7), Vector2(316.8, 517.8), Vector2(311, 517.5), Vector2(305.6, 515.4), Vector2(300.3, 512.8), Vector2(294.8, 510.8), Vector2(289, 510.8), Vector2(283.7, 513.5), Vector2(279, 517), Vector2(275.5, 521.7), Vector2(275.1, 527.4), Vector2(277.4, 532.8), Vector2(279.1, 538.5), Vector2(280.2, 544.3), Vector2(281, 550.1), Vector2(282, 555.9), Vector2(284.4, 561.2), Vector2(289.2, 564.6), Vector2(294.8, 564.4), Vector2(296.2, 559), Vector2(298.7, 554.1), Vector2(304.3, 552.6), Vector2(310.2, 552.7), Vector2(316.1, 553.4), Vector2(321.8, 554.7), Vector2(327, 557.2), Vector2(326.6, 562.6), Vector2(322, 566.2), Vector2(316.6, 568.4), Vector2(311.3, 571), Vector2(307.1, 575.1), Vector2(304.4, 580.3), Vector2(301.6, 585.2), Vector2(296.9, 588.7), Vector2(291.5, 591.2), Vector2(285.8, 592.3), Vector2(280, 591.6), Vector2(274.8, 588.9), Vector2(270.7, 584.7), Vector2(267.5, 579.7), Vector2(265, 574.4), Vector2(263.1, 568.8), Vector2(261.7, 563.1), Vector2(260.7, 557.3), Vector2(260.1, 551.5), Vector2(260.1, 545.6), Vector2(260.5, 539.7), Vector2(260.8, 533.8), Vector2(261.1, 528), Vector2(261.5, 522.1), Vector2(261.9, 516.2), Vector2(262.4, 510.3), Vector2(263.1, 504.5), Vector2(264.1, 498.7), Vector2(265.4, 493), Vector2(267.4, 487.4), Vector2(270.9, 482.8), Vector2(276.3, 481.1), Vector2(282.1, 482), Vector2(287.8, 483.5), Vector2(293.4, 485.4), Vector2(298.9, 487.3)]),
	PackedVector2Array([Vector2(298.9, 487.3), Vector2(304.5, 489.3), Vector2(310.1, 491.1), Vector2(315.7, 492.8), Vector2(321.5, 494.1), Vector2(327.3, 494.9), Vector2(333.2, 494.8), Vector2(338.7, 493), Vector2(343.9, 490.2), Vector2(349.2, 487.6), Vector2(354.5, 485.2), Vector2(359.9, 482.8), Vector2(365.3, 480.4), Vector2(370.8, 478.2), Vector2(376.2, 476), Vector2(381.7, 473.8), Vector2(387.2, 471.7), Vector2(392.7, 469.7), Vector2(398.3, 467.7), Vector2(403.8, 465.8), Vector2(409.5, 464.1), Vector2(415.1, 462.4), Vector2(420.8, 461), Vector2(426.6, 459.9), Vector2(432.4, 459.4), Vector2(437.9, 461), Vector2(439.8, 466.4), Vector2(441.1, 472.2), Vector2(442.2, 477.9), Vector2(443.2, 483.7), Vector2(444.2, 489.6), Vector2(445.1, 495.4), Vector2(446, 501.2), Vector2(446.9, 507), Vector2(447.7, 512.8), Vector2(448.6, 518.7), Vector2(449.6, 524.5), Vector2(450.6, 530.3), Vector2(451.5, 536.1), Vector2(451.8, 541.9), Vector2(451.4, 547.8), Vector2(450.6, 553.6), Vector2(449.5, 559.4), Vector2(448.3, 565.2), Vector2(446.9, 570.9), Vector2(445.3, 576.6), Vector2(443.7, 582.2), Vector2(441.9, 587.8), Vector2(440, 593.4), Vector2(438.1, 599), Vector2(436, 604.5), Vector2(433.9, 610), Vector2(432.2, 615.6), Vector2(430.5, 621.3), Vector2(427.7, 626.4), Vector2(423.6, 630.6), Vector2(418.8, 634), Vector2(414.3, 637.8), Vector2(410.4, 642.2), Vector2(405.9, 646), Vector2(400.4, 648), Vector2(394.6, 648.7), Vector2(388.7, 648.7), Vector2(382.8, 648.4), Vector2(376.9, 647.8), Vector2(371.1, 646.9), Vector2(365.3, 645.8), Vector2(359.7, 644.3), Vector2(354.1, 642.5), Vector2(349.9, 644.2), Vector2(348.9, 650), Vector2(348.2, 655.9), Vector2(348, 661.8), Vector2(348.7, 667.6), Vector2(349.7, 673.4), Vector2(350, 679.2), Vector2(350.2, 685.1), Vector2(350.3, 688.1)]),
	]
