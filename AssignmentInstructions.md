Utveckla ett kontrakt som fungerar som en prenumerationsplattform, där vem som helst kan skapa sin egen prenumerationstjänst.
Varje skapad prenumerationstjänst ska ha en ägare, en avgift och en periodlängd (t.ex. 30 dagar), samt kunna pausas eller återupptas individuellt. Kontraktet ska ha funktioner för att betala för eller förlänga en prenumeration, kontrollera om en adress har en aktiv prenumeration, samt hämta slutdatum för aktiva prenumerationer. Det ska även vara möjligt att ge bort en prenumeration till någon annan. Skaparen av en prenumerationstjänst ska kunna ändra avgiften för prenumerationen, pausa eller återuppta just sin tjänst, samt ta ut de intäkter som har samlats in för den aktuella prenumerationen.

- Prenumurera på en tjänst X
- hämta slutdataum för alla aktiva prenumerationer X
- ge bort en prenumeration till någon annan X
- sercvice provider ska kunna ta ut pengar

Grundläggande krav (G):
Kontraktet ska innehåll följande element:

- Minst en struct eller enum
- Minst en mapping eller array
- En constructor
- Minst en custom modifier
- Minst ett event för att logga viktiga händelser
- Utöver ovanstående krav ska ni även skriva tester för kontraktet som täcker - grundläggande funktionalitet. Säkerställer att alla viktiga funktioner fungerar som förväntat, samt att ni har ett test coverage på minst 40%.

För att nå VG ska ni uppfylla samtliga krav för G-nivå, samt:

- Kontraktet ska innehålla minst ett custom error, samt minst en require, en assert, och en revert
- Kontraktet ska innehålla en fallback och/eller receive funktion
- Distribuera ert smarta kontrakt till Sepolia och verifiera kontraktet på Etherscan. Länka till den verifierade kontraktssidan i er inlämning.
- Säkerställ att ert kontrakt har ett test coverage på minst 90%.
- Identifiera och implementera minst tre gasoptimeringar och/eller säkerhetsåtgärder i ert kontrakt (användning av senaste versionen av solidity eller optimizer räknas ej!). Förklara vilka åtgärder ni har vidtagit, varför de är viktiga, och hur de förbättrar gasanvändningen och/eller kontraktets säkerhet.
