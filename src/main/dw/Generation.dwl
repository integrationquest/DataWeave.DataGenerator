%dw 2.0
import take from dw::core::Arrays
import * from mocks::helpers::RandomHelpers
import * from mocks::constants::DataConstants
import * from mocks::DataGenerators
import * from dw::core::Strings

var coldReferralCodes = {
    WEBSIGNUP: 4,
    CALLCENTER: 3,
    COLDEMAIL: 1
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

fun generateCustomers(count: Number, generations: Number, referralCodes = coldReferralCodes, existing: Array<Customer> = []): Array<Customer> =
    if (sizeOf(existing) >= count) existing take count
    else do {
        var baseReferralCode = pickRandom(
            flatten(referralCodes pluck (weight, code) -> 
                (1 to weight) map code))
        var inviter = customers(1, baseReferralCode)[0]
        var referrals = generateReferrals(generations, count - sizeOf(existing), [inviter.inviteCode])
        // var forLog = log("referrals for $(inviter.inviteCode)", sizeOf(referrals))
        ---
        generateCustomers(count, generations, referralCodes, (existing << inviter) ++ referrals)
    }

fun numberOfInvites(): Number = if (random() < 0.6) 0 // many people never invite anyone
    else do {
        var socialFactor = 2 pow randomInt(7)
        var count = socialFactor - randomInt(socialFactor)
        ---
        count
    }
@TailRec
fun generateReferrals(generations: Number, max: Number, codes: Array<String>, invited: Array<Customer> = []): Array<Customer> =
    if (generations == 0) invited
    else do {
        // var forLog = log("generating referrals for $(generations) generations", codes)
        var nextGeneration = codes reduce (code, people = []) ->
            if (sizeOf(people) > max) people
            else do {
                var needed = max - (sizeOf(people) + sizeOf(invited))
                var planned = numberOfInvites()
                var count = if (needed < planned) needed else planned
                ---
                people ++ customers(count, code)
            }
        ---
        generateReferrals(generations - 1, max, nextGeneration map $.inviteCode, invited ++ nextGeneration)
    }


fun customers(count: Number, referredBy: String): Array<Customer> =
  if (count == 0) [] else (1 to count) map do {
    var name = newName()
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
        referred: referredBy
    }
  }