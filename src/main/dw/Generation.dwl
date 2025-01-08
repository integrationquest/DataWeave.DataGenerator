%dw 2.0
import take from dw::core::Arrays
import * from mocks::helpers::RandomHelpers
import * from mocks::constants::DataConstants
import * from mocks::DataGenerators
import * from dw::core::Strings
import * from dw::core::Periods

var coldReferralCodes = {
    WEBSIGNUP: 4,
    CALLCENTER: 3,
    COLDEMAIL: 1
}
var launchDate = |2024-04-04T06:30:00-05:00|
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

fun numberOfInvites(): Number = if (random() < 0.6) 0 // many people never invite anyone
    else do {
        var socialFactor = 2 pow randomInt(7)
        var count = socialFactor - randomInt(socialFactor)
        ---
        count
    }
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

fun newSignUpDate(after: DateTime): DateTime = do {
    var daysSinceLaunch = (now() - after).days
    // squaring a random in [0,1) favors small values
    // var daysAgo = floor((random() * random()) * daysSinceLaunch)
    var daysAgo = randomInt(daysSinceLaunch) + 1
    // summing two randoms gives a normal distribution (poisson)
    var secondOfDay = floor((random() + random()) / 2 * 86400) + 6 * 3600
    var daysAfterLaunch = daysSinceLaunch - daysAgo
    ---
    after + period({days: daysAfterLaunch}) + duration({seconds: secondOfDay})
}

fun customers(count: Number, referredBy: String, after: DateTime = launchDate): Array<Customer> =
  if (count == 0) [] else (1 to count) map do {
    var name = newName()
    var signedUp = newSignUpDate(after)
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