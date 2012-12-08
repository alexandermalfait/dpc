namespace :dpc do
  namespace :batch_search do
    task :nouns => :environment do
      words = "aanmoedigingspremie
aanval
adreskaartje
adviseur
afdeling
afdrukken
afgeleide toepassing
afkomst
africhten
afstamming
algemeen plan
Amerikaanse dollar
apparaat
artiest
artikel
baan
baantje
bedrijfsleiding
bedrijfsmodel
beeldscherm
begeleiden
begeleider
beginnend bedrjf
begroting
beheer
belegging
beloning
beroerte
besturingsprogramma
bestuur
bestuurder
betoog
betrekking
bijeenkomst
bijproduct
binnen-
bromfiets
brommer
combinatie
comfort
compromis
computerprogramma
consument
controle
controleren
deelhebberschap
detailhandel
diagonaal lezen
dienst na verkoop
dienstverlening
directeur
divisie
doel
drijven
eenheid
elektronische post
etiket
exploiteren
fenomeen
gebruikersinterface
geïntegreerde schakeling
geluidsbox
gereedschap
geruchten
gesprek
groep
halfgeleiderlampje
helpen
hoeveelheid
houdstermaatschappij
hulpmiddel
huurkoop
ijkpunt
informatie- en communicatietechnologie
internet
investering
invoer
koppeling
leiden
leider
levering
lied
liedje
machtiging
mail
mailtje
marketingman
marktanalyse
marktonderzoek
marktverkenning
medespeler
mengeling
mengsel
merk
mixtuur
mobiele telefoon
mobieltje
nabehandeling
natrekken
nawerking
net
netwerk
octrooi
oefenen
oefenmeester
omzetdoelstelling
ondervraging
onderzoek
onderzoek en ontwikkeling
oorkonde
oorsprong
opbrengst
opslag
optisch lezen
origine
overeenkomst
overname
overnamepremie
pagina
partnerschap
patent
persoonlijke levenssfeer
planning
ploeg
popsong
preek
president-directeur
privaat vermogen
privésfeer
producent
programmatuur
reclamebord
rede
redement
redevoering
regisseur
richtlijn
samenwerkingsverband
schakel
scherm
sms-bericht
smsje
sociëteit
spanning
starter
stel
technologie
telefax
telefoon
tendens
terugkoppeling
tijdslimiet
toepassingsprogramma
toespraak
toevoer
toost
transactie
uitdraaien
uitprinten
ultimatum
vakkennis
vennoot
verband
verbinden
vergadering
vergelijken
verifiëren
verklaring
vervolg
verwijzing
volmacht
voorzitter
vraaggesprek
weblocatie
webpagina
webstek
welwillendheid
werkdruk
winst
wortels".split("\n").collect(&:strip)

      searcher = BatchSearcher.new(words, ["NL-BE"], "batch_results/alternatieven_NL")

      searcher.execute
    end
  end

end