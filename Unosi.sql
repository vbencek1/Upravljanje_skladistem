begin;
INSERT INTO Zaposlenici VALUES('11111111111', 'Valentino','Bencek','091/786-7777','val@mail.com',
'adresa 1234, Varazdin',current_timestamp);
INSERT INTO Zaposlenici VALUES('22222222222', 'Ivo','Ivic','091/786-1111','iivic@mail.com',
'adresa 2222, Zagreb',current_timestamp);


INSERT INTO Vrsta_poslovnog_partnera VALUES(1,'Dobavljac');
INSERT INTO Vrsta_poslovnog_partnera VALUES(2,'Kupac');
insert into vrsta_racuna VALUES (1,'Prodaja');
insert into vrsta_racuna VALUES (2,'Dostava');
insert into vrsta_artikla values(1,'mlijeko','mlijeko');
insert into vrsta_artikla values(2,'sok','negazirani sok');
insert into vrsta_artikla values(3,'jogurt','mlijecni jogurt');

INSERT INTO Poslovni_partneri VALUES('33333333333', 'Stef','Stefic','091/111-7777','sstef@mail.com',
'adresa 15, Varazdin',current_timestamp,1);
INSERT INTO Poslovni_partneri VALUES('44444444444', 'Lovro','Lovric','091/111-2222','llovro@mail.com',
'adresa 11, Varazdin',current_timestamp,2);


insert into racuni VALUES (default, default, current_timestamp, 2, '11111111111', '33333333333'); 
insert into racuni VALUES (default, default, current_timestamp, 1, '22222222222', '44444444444');


INSERT INTO artikli VALUES(default, 'Mlijeko 2.8%',6.53,current_timestamp,1);
INSERT INTO artikli VALUES(default, 'Sok jabuka',3.53,current_timestamp,2);
INSERT INTO artikli VALUES(default, 'Jogurt 1.1%',10.00,current_timestamp,3);

INSERT INTO Skladista VALUES(default, 'Trajno 1','Skladiste trajnih proizvoda','adresa 11 Varazdin'
,current_timestamp);
INSERT INTO Skladista VALUES(default, 'Hladnjaca 1','Skladiste hladnih proizvoda','adresa 11 Varazdin'
,current_timestamp);

insert into artikli_na_skladistu VALUES (1,1,100);
insert into artikli_na_skladistu VALUES (1,2,200);
insert into artikli_na_skladistu VALUES (2,2,200);
insert into artikli_na_skladistu VALUES (3,2,100);

insert into artikli_na_racunu VALUES (1,1,1,10);
insert into artikli_na_racunu VALUES (1,2,2,5);
insert into artikli_na_racunu VALUES (2,1,2,10);
insert into artikli_na_racunu VALUES (2,3,2,5);


commit;