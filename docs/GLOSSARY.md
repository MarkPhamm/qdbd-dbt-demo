# Skytrax Reviews

Passenger reviews from Skytrax (AirlineQuality.com), modelled as four star schemas that share one set of dimensions.

## Reviews

**Review**:
One submission a reviewer left on Skytrax about one subject. The grain of every fact.
_Avoid_: Rating, post, feedback

**Subject**:
What a review is about: an airline (a flight), an airport, a lounge or a seat. Each subject has its own fact.
_Avoid_: Review type, category

**Reviewer**:
The person behind a review, identified only by name and nationality. A proxy: two people who share both are one reviewer.
_Avoid_: User, passenger, customer (the column is `customer_id`, the concept is a reviewer)

**Re-ingested duplicate**:
The same review stored again under a new `review_id` when the source was scraped twice. Identified by reviewer, subject, date and text, not by id.
_Avoid_: Duplicate review id

## Ratings

**Category rating**:
A 1 to 5 score for one aspect of a subject, such as seat comfort or lounge cleanliness. A reviewer may leave any of them blank.
_Avoid_: Score, stars

**Average rating**:
The mean of the category ratings a reviewer actually gave. Blank categories do not count.
_Avoid_: Overall rating, score

**Rating band**:
The average rating bucketed as bad, medium or good, or unknown when no category was rated.
_Avoid_: Sentiment, grade

**Recommended**:
Whether the reviewer says they would recommend the subject. Stated by the reviewer, and may contradict their ratings.

## Places and cabins

**Location**:
A city and airport code a flight started, ended or changed planes at.
_Avoid_: Stop, station

**Lounge access tier**:
The way the reviewer got into a lounge, such as Business Class or Pay to Use. The same lounge reviewed under two tiers is two lounges.
_Avoid_: Lounge type, class

**Cabin**:
The class of travel a reviewer flew: Economy Class, Premium Economy, Business Class or First Class.
_Avoid_: Seat type, class of service

**Route**:
An origin and destination location pair, regardless of airline or layover.
_Avoid_: Flight, leg
