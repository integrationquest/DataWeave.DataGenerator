%dw 2.0
import take from dw::core::Arrays
import * from dw::core::Dates
import * from dw::core::Strings
import * from dw::core::Periods
import * from dw::iq::RandomUtils
import * from mocks::helpers::RandomHelpers
import * from mocks::constants::DataConstants
import * from mocks::DataGenerators

var coldReferralCodes = {
    WEBSIGNUP: 4,
    CALLCENTER: 3,
    COLDEMAIL: 1
}
var launchDate = |2022-02-22T06:30:00-05:00|
var promoDates = do {
    var daysSinceLaunch = (now() - launchDate) as Number {unit: "days"}
    ---
    (1 to 6) map launchDate + days(randomInt(daysSinceLaunch))
}
var usCities = readUrl("classpath://uscities.csv", "application/csv")
var userWords = readUrl("classpath://username-words.csv", "application/csv") map $.word

type ContactName = {
    first: String,
    last: String
}

type Address = {
        street: String,
        city: String,
        state: String,
        postalCode: String,
    }

type Customer = {
    id: String,
    inviteCode: String,
    name: ContactName,
    address: Address,
    contact: {
        phone: String,
        email: String,
    },
    signUp: DateTime,
    referred: String
}

var INVITE_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
fun newInviteCode(): String = 
    ((0 to 14) map pickRandom(INVITE_CHARS splitBy "")) joinBy ""
fun newName() = {
    first: randomFirstName(),
    last: randomLastName()
}

fun newAddress(): Address = do {
    var cityData = randomInt(16) match {
        case i if i < 10 -> pickRandom(usCities filter (city) -> city.ranking as Number == 1)
        case i if i < 14 -> pickRandom(usCities filter (city) -> city.ranking as Number == 2)
        else -> pickRandom(usCities filter (city) -> city.ranking as Number > 2)
    }
    ---
    {
        street: capitalize(randomAddress()),
        city: cityData.city as String,
        state: cityData.state_id as String,
        postalCode: pickRandom(cityData.zips splitBy " ") as String
    }
}

fun newEmail(name: ContactName): String = do {
    var username = randomInt(32) match {
        case i if i < 16 -> "$(name.first).$(name.last)"
        case i if i < 24 -> "$(name.last)$(name.first[0])"
        case i if i < 28 -> "$(name.first[0])$(name.last)$(randomInt(1000))"
        case i if i < 30 -> "$(pickRandom(userWords))$(name.first))"
        else -> "$(pickRandom(userWords))$(randomInt(100))"
    }
    var domain = randomInt(16)  match {
        case i if i < 10 -> pickRandom(["gmail.com", "hotmail.com", "outlook.com"])
        else -> pickRandom(DOMAIN_NAMES)
    }
    ---
    "$(username)@$(domain)"
}

fun generateCustomers(count: Number, generations: Number = 6, existing: Array<Customer> = []): Array<Customer> =
    if (sizeOf(existing) >= count) existing take count
    else do {
        var baseReferralCode = pickRandom(
            flatten(coldReferralCodes pluck (weight, code) -> 
                (1 to weight) map code))
        var inviter = customers(1, baseReferralCode)[0]
        var referrals = generateReferrals(generations, count - sizeOf(existing), [inviter])
        // var forLog = log("referrals for $(inviter.inviteCode)", sizeOf(referrals))
        ---
        generateCustomers(count, generations, (existing << inviter) ++ referrals)
    }

fun numberOfInvites(): Number = if (random() < 0.5) 0 // many people never invite anyone
    else floor(logNormal() * 3 * 2) // mode should be 2 invites
@TailRec
fun generateReferrals(generations: Number, max: Number, inviters: Array<Customer>, invited: Array<Customer> = []): Array<Customer> =
    if (generations == 0) invited
    else do {
        // var forLog = log("generating referrals for $(generations) generations", codes)
        var nextGeneration = inviters reduce (inviter, people = []) ->
            if (sizeOf(people) > max) people
            else do {
                var needed = max - (sizeOf(people) + sizeOf(invited))
                var planned = numberOfInvites()
                var count = if (needed < planned) needed else planned
                ---
                people ++ customers(count, inviter.inviteCode, inviter.signUp)
            }
        ---
        generateReferrals(generations - 1, max, nextGeneration, invited ++ nextGeneration)
    }

fun newSignUpDate(after: DateTime): DateTime = if (after > (now() - |PT1M|)) after
    else do {
        var age: Period = (now() - after)
        var signUpTime: Period = 
        if (age as Number {unit: "minutes"} < 90) seconds(randomInt(age.seconds))
        else if (age as Number {unit: "days"}  < 3) do {
            var modeMinutes = 45
            var secs = logNormalCapped(age.minutes / modeMinutes) * modeMinutes * 60
            ---
            seconds(floor(secs))
        } else do {
            var modeDays = 2
            // doing this in seconds
            var secondsPastMidnight = after - atBeginningOfDay(after)
            var delayDays = floor(logNormalCapped((age as Number {unit: "days"} - 1) / modeDays / 3) * modeDays * 3)
            var meanTimeOfDay = 14 * 60 * 60
 
            var signUpDelta = floor(gaussian() * 3 * 60 * 60)
            var totalDelaySecs = delayDays * 86400 - secondsPastMidnight + meanTimeOfDay + signUpDelta
            ---
            seconds(totalDelaySecs)
        }
        var result = after + signUpTime
        ---
        if (result > after) result else newSignUpDate(after)
    }

fun customers(count: Number, referredBy: String, after: DateTime = launchDate): Array<Customer> =
  if (count == 0) [] else (1 to count) map do {
    var name = newName()
    var signedUp = if (after == launchDate and random() < 0.3) do {
        // mix up the cold sign up dates
        newSignUpDate(pickRandom(promoDates))
    } else newSignUpDate(after)
    ---
    {
        id: randomId(32),
        inviteCode: newInviteCode(),
        name: name,
        address: newAddress(),
        contact: {
            phone: randomPhoneNumber(),
            email: newEmail(name)
        },
        signUp: signedUp,
        referred: referredBy
    }
  }