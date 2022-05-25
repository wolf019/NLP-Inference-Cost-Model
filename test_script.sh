#!/bin/zsh

# Use $RANDOM for random number register

text_data='{
	"v1":"Fears for T N pension after talks Unions representing workers at Turner Newall say they are disappointed after talks with stricken parent firm Federal Mogul.",
	"v2":"Vladimir Putin has indicated that Russia could rip up contracts to supply gas to Europe unless “unfriendly” states drop their refusal to pay in roubles from Friday. To buy Russian gas, they need to open rouble accounts in Russian banks,” Putin said in a televised appearance on Thursday. It is from those accounts that gas will be paid for, starting 1 April. If such payments aren’t made, we will consider this a failure by the client to comply with its obligations.” The threat of a gas shutoff was reduced, however, as details emerged about the new deal, which appeared to allow European buyers to continue to pay for gas in euros and dollars. The decree Putin signed on Thursday authorises the state-controlled Gazprombank to open foreign currency and rouble accounts for gas purchases. European buyers would pay in foreign currency and then authorise Gazprombank to make the conversion into roubles, which would then be used to formally purchase the gas.",
	"v3":"Anya Shrubsole says England will be there or thereabouts against Australia in Womens World Cup final if they play like they did against South Africa in semi-finals Sky Sports Nasser Hussain insists England must be at their best live on Sky Sports from 1am on Sunday",
	"v4":"With only one month to go until Frances presidential election in April, the office of Marine Le Pen, the leader of the French far-right party the National Rally, sent the usual Sunday email outlining her schedule for the coming week as “candidate for the presidency of the Republic.” Unfortunately for Le Pen, many of its recipients were at that moment en route to a rally for her rival, where several formerly trusted members of her inner circle would fill the front row. Ever since Éric Zemmour, a far-right pundit and former newspaper columnist, declared his own candidacy for president last November, members of Le Pens party had been departing in a steady trickle for his. And yet there was something particularly plaintive in Le Pens notification. A final defection was expected that day — that of her niece, Marion Maréchal, quite likely spelling the end of Le Pen and of her partys hold over the far right."
}'

# Scenario 1,	Simulate a period of 500 requests to a Apples Siri like Application.
# 		The scenario sends one text per requests with a sleep in between of
#		value 1000 - 0 milliseconds. 500 inferences


RANDOM=42 # Make sure script use the same text sequence for all tests
for i in {1..1}
do
	#request
	json='{
        "instances": [
                {"text":'$(jq ".v$[${RANDOM}%4+1]" <(echo "$text_data"))'}
        ]}'

	# Send request
	curl -H "Content-Type: application/json" -X POST -d "$json" localhost:8080/predict

	# Sleep 1000ms - 0ms
        sleep $(echo "(($RANDOM%1000)+1)*0.001" | bc)
done


# Scenario 2, Simulate burst requests. 10 requests every 2 second for 10 batches. 100 inferences.

RANDOM=42
for i in {1..1}
do
	# init request
	echo '{"instances":[]}' > text.json

	# build reques of 10 texts to classify
	for i in {1..10}
        	do
			data='{"text":'$(jq ".v$[${RANDOM}%4+1]" <(echo "$text_data"))'}'
               		echo $(jq --argjson str "$data" '.instances[.instances | length] |= . + $str' text.json) > text.json
        	done
	# Send request
        curl -H "Content-Type: application/json" -X POST -d @./text.json localhost:8080/predict

	# Sleep 2 seconds
        sleep 2
done


# Scenario 3, Simulate one computation heavy request. 500 inferences made in one request.

RANDOM=42

# init request
echo '{"instances":[]}' > text.json

# build the request with 500 texts to classify
for i in {1..500}
do
        data='{"text":'$(jq ".v$[${RANDOM}%4+1]" <(echo "$text_data"))'}'
	echo $(jq --argjson str "$data" '.instances[.instances | length] |= . + $str' text.json) > text.json
done

curl -H "Content-Type: application/json" -X POST -d @./text.json localhost:8080/predict

# All scenarios are done
echo Done!
