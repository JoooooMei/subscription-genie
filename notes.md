Jag försöker gasopitmera. Funderar på aom man kan använda bytes32 istället för string för name i structen. Jag tror jag sparar mycket gas men är det värt det??? Jag försöker även få in flera variabler i samma minnesslot. Det är lite proffsigt. Sparar inte lika mycket men påverkar inte hur sidigt kontraktet blir att interagera med.

Sätter owner till public som jag tror blir billigare än göra den private och sedan skriva en getterfunktion

Introducerar modifier som borde sänka gaskostnaden vid deploy

Lägger inte till subscriptionEndDate i structen. Detta gör det lite billigare att teckna en prenumeration vilket jag är nöjd med. Det blir lite krångligare att pussla ihop det i frontend sedan men jag är i alla fall medveten om det.
