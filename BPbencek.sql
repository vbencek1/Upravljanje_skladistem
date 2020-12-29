begin;
CREATE TABLE Zaposlenici ( oib VARCHAR(11) PRIMARY KEY,
ime VARCHAR (30) NOT NULL , prezime VARCHAR (30) NOT NULL, 
mobitel VARCHAR (30), email VARCHAR (30), adresa VARCHAR (30), vrijeme_unosa TIMESTAMP) ;

CREATE TABLE Vrsta_poslovnog_partnera ( id_vrste_partnera SERIAL PRIMARY KEY,
naziv VARCHAR (30) NOT NULL) ;

CREATE TABLE Poslovni_partneri ( oib VARCHAR(11) PRIMARY KEY,
ime VARCHAR (30) NOT NULL , prezime VARCHAR (30) NOT NULL, 
mobitel VARCHAR (30), email VARCHAR (30), adresa VARCHAR (30), vrijeme_unosa TIMESTAMP,
vrsta_partnera INT REFERENCES Vrsta_poslovnog_partnera (id_vrste_partnera)
ON DELETE CASCADE ON UPDATE CASCADE NOT NULL) ;

CREATE TABLE Vrsta_racuna ( id_vrste_racuna SERIAL PRIMARY KEY,
naziv VARCHAR (30) NOT NULL);

CREATE TABLE Racuni ( id_racuna SERIAL PRIMARY KEY,
ukupna_cijena decimal(10,2) DEFAULT 0.00, vrijeme_izdavanja TIMESTAMP,
vrsta_racuna INT REFERENCES Vrsta_racuna (id_vrste_racuna)
ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
zaposlenik VARCHAR(11) REFERENCES Zaposlenici (oib)
ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
poslovni_partner VARCHAR(11) REFERENCES Poslovni_partneri (oib)
ON DELETE CASCADE ON UPDATE CASCADE NOT NULL );

CREATE TABLE Vrsta_artikla ( id_vrste_artikla SERIAL PRIMARY KEY,
naziv VARCHAR (30) NOT NULL, opis VARCHAR(255));

CREATE TABLE Artikli ( id_artikla SERIAL PRIMARY KEY,
naziv VARCHAR (30) NOT NULL , cijena decimal(10,2) NOT NULL, vrijeme_unosa TIMESTAMP,
vrsta_artikla INT REFERENCES Vrsta_artikla (id_vrste_artikla)
ON DELETE CASCADE ON UPDATE CASCADE NOT NULL) ;

CREATE TABLE Skladista ( id_skladista SERIAL PRIMARY KEY,
naziv VARCHAR (30) NOT NULL , opis VARCHAR(255),lokacija VARCHAR(100), vrijeme_unosa TIMESTAMP);

CREATE TABLE Artikli_na_racunu ( id_racuna INT REFERENCES Racuni (id_racuna)
ON DELETE CASCADE ON UPDATE CASCADE,
id_artikla INT REFERENCES Artikli (id_artikla)
ON DELETE CASCADE ON UPDATE CASCADE,
id_skladista INT REFERENCES Skladista (id_skladista)
ON DELETE CASCADE ON UPDATE CASCADE,
kolicina INT,
PRIMARY KEY (id_racuna, id_artikla, id_skladista));



CREATE TABLE Artikli_na_skladistu ( 
 id_artikla INT REFERENCES Artikli (id_artikla)
ON DELETE CASCADE ON UPDATE CASCADE,
id_skladista INT REFERENCES Skladista (id_skladista)
ON DELETE CASCADE ON UPDATE CASCADE,
kolicina INT,
PRIMARY KEY (id_artikla,id_skladista));



CREATE OR REPLACE FUNCTION provjeraOiba()
	RETURNS TRIGGER
	AS $$
		BEGIN
			IF char_length(NEW.oib) =11 THEN
				RETURN NEW;
			ELSE
				RAISE EXCEPTION '%' ,
				'OIB ne sadrzi 11 znakova!';
			END IF ;
		END;
	$$
	LANGUAGE plpgsql ;
	
CREATE TRIGGER provjeraOibaTr
	BEFORE INSERT OR UPDATE
	ON Zaposlenici
	FOR EACH ROW EXECUTE PROCEDURE provjeraOiba();
	
CREATE TRIGGER provjeraOibaTr2
	BEFORE INSERT OR UPDATE
	ON Poslovni_partneri
	FOR EACH ROW EXECUTE PROCEDURE provjeraOiba();

CREATE OR REPLACE FUNCTION provjeraOiba2()
	RETURNS TRIGGER
	AS $$
		BEGIN
			IF (select new.oib ~ '^[0-9]+$') THEN
				RETURN NEW;
			ELSE
				RAISE EXCEPTION '%' ,
				'OIB mora biti broj!';
			END IF ;
		END;
	$$
	LANGUAGE plpgsql ;
	
CREATE TRIGGER provjeraOibaBrojTr
	BEFORE INSERT OR UPDATE
	ON Zaposlenici
	FOR EACH ROW EXECUTE PROCEDURE provjeraOiba2();
	
CREATE TRIGGER provjeraOibaBrojTr2
	BEFORE INSERT OR UPDATE
	ON Poslovni_partneri
	FOR EACH ROW EXECUTE PROCEDURE provjeraOiba2();
	
	
CREATE OR REPLACE FUNCTION provjeraEmaila()
	RETURNS TRIGGER
	AS $$
		BEGIN
			IF new.email LIKE '%@%.%' THEN
				RETURN NEW;
			ELSE
				RAISE EXCEPTION '%' ,
				'Email nije odgovarajuceg formata!';
			END IF ;
		END;
	$$
	LANGUAGE plpgsql ;
	
CREATE TRIGGER provjeraEmailaTr
	BEFORE INSERT OR UPDATE
	ON Zaposlenici
	FOR EACH ROW EXECUTE PROCEDURE provjeraEmaila();
	
CREATE TRIGGER provjeraEmailaTr2
	BEFORE INSERT OR UPDATE
	ON Poslovni_partneri
	FOR EACH ROW EXECUTE PROCEDURE provjeraEmaila();
	
CREATE OR REPLACE FUNCTION azurirajUkupnuCijenu()
	RETURNS TRIGGER
	AS $$
	DECLARE
	ukupno decimal(10,2);
	cijenaArt decimal(10,2);
	kolicinaArt decimal(10,2);
	racunica decimal(10,2);
		BEGIN
		select cijena into cijenaArt from Artikli where Artikli.id_artikla=new.id_artikla;
		select ukupna_cijena into ukupno from Racuni where Racuni.id_racuna= new.id_racuna;
		kolicinaArt=new.kolicina;
		racunica= ukupno+(cijenaArt*kolicinaArt);
		update Racuni set ukupna_cijena=racunica where Racuni.id_racuna=new.id_racuna;	
		return new;
		END;
	$$
	LANGUAGE plpgsql;
	
CREATE TRIGGER azurirajUkupnuCijenuTr
	After INSERT
	ON Artikli_na_racunu
	FOR EACH ROW EXECUTE PROCEDURE azurirajUkupnuCijenu();


CREATE OR REPLACE FUNCTION azurirajStanjeSkladista()
	RETURNS TRIGGER
	AS $$
	DECLARE
	kolicinaUku int;
	vrstaRac int;
		BEGIN
		select kolicina into kolicinaUku from Artikli_na_skladistu 
				where Artikli_na_skladistu.id_skladista=new.id_skladista
				and Artikli_na_skladistu.id_artikla=new.id_artikla;
		
		select vrsta_racuna into vrstaRac from Racuni where Racuni.id_racuna= new.id_racuna;
		
		if vrstaRac = 1 then
		
			kolicinaUku=kolicinaUku - new.kolicina;
		
				if(kolicinaUku>=0) then
				update Artikli_na_skladistu set kolicina=kolicinaUku where Artikli_na_skladistu.id_skladista=new.id_skladista
						and Artikli_na_skladistu.id_artikla=new.id_artikla;	
				else
				RAISE EXCEPTION '%' ,
						'Na skladistu nema dovoljno artikala!';
				END IF ;
		end if;
		if vrstaRac = 2 then
			kolicinaUku=kolicinaUku + new.kolicina;
			update Artikli_na_skladistu set kolicina=kolicinaUku where Artikli_na_skladistu.id_skladista=new.id_skladista
						and Artikli_na_skladistu.id_artikla=new.id_artikla;
		end if;
		return new;
		END;
	$$
	LANGUAGE plpgsql;
	
CREATE TRIGGER azurirajStanjeSkladistaTr
	After INSERT
	ON Artikli_na_racunu
	FOR EACH ROW EXECUTE PROCEDURE azurirajStanjeSkladista();



CREATE OR REPLACE FUNCTION azurirajUkupnuCijenuKodBrisanja()
	RETURNS TRIGGER
	AS $$
	DECLARE
	ukupno decimal(10,2);
	cijenaArt decimal(10,2);
	kolicinaArt decimal(10,2);
	racunica decimal(10,2);
		BEGIN
		select cijena into cijenaArt from Artikli where Artikli.id_artikla=old.id_artikla;
		select ukupna_cijena into ukupno from Racuni where Racuni.id_racuna= old.id_racuna;
		kolicinaArt=old.kolicina;
		racunica= ukupno-(cijenaArt*kolicinaArt);
		update Racuni set ukupna_cijena=racunica where Racuni.id_racuna=old.id_racuna;	
		return old;
		END;
	$$
	LANGUAGE plpgsql;
	
CREATE TRIGGER azurirajUkupnuCijenuKodBrisanjaTr
	After DELETE
	ON Artikli_na_racunu
	FOR EACH ROW EXECUTE PROCEDURE azurirajUkupnuCijenuKodBrisanja();




CREATE OR REPLACE FUNCTION azurirajStanjeSkladistaKodBrisanja()
	RETURNS TRIGGER
	AS $$
	DECLARE
	kolicinaUku int;
	vrstaRac int;
		BEGIN
		select kolicina into kolicinaUku from Artikli_na_skladistu 
				where Artikli_na_skladistu.id_skladista=old.id_skladista
				and Artikli_na_skladistu.id_artikla=old.id_artikla;
		select vrsta_racuna into vrstaRac from Racuni where Racuni.id_racuna= old.id_racuna;
		
		if vrstaRac = 1 then
		kolicinaUku=kolicinaUku + old.kolicina;
		
		update Artikli_na_skladistu set kolicina=kolicinaUku where Artikli_na_skladistu.id_skladista=old.id_skladista
				and Artikli_na_skladistu.id_artikla=old.id_artikla;	
		end if;
		if vrstaRac=2 then
		kolicinaUku=kolicinaUku - old.kolicina;
		
		update Artikli_na_skladistu set kolicina=kolicinaUku where Artikli_na_skladistu.id_skladista=old.id_skladista
				and Artikli_na_skladistu.id_artikla=old.id_artikla;
		end if;
		return old;
		END;
	$$
	LANGUAGE plpgsql;
	
CREATE TRIGGER azurirajStanjeSkladistaKodBrisanjaTr
	After DELETE
	ON Artikli_na_racunu
	FOR EACH ROW EXECUTE PROCEDURE azurirajStanjeSkladistaKodBrisanja();
	
	
	
	
CREATE TABLE narudzbenica (id_artikla INT REFERENCES Artikli (id_artikla) ON DELETE CASCADE,
	id_skladista INT REFERENCES Skladista (id_skladista) ON DELETE CASCADE,	
	kolicina INT default 0, status VARCHAR(30), 
	PRIMARY KEY (id_artikla, id_skladista));


CREATE OR REPLACE FUNCTION StrategijaZaliha()
	RETURNS TRIGGER
	AS $$
	DECLARE
	kolicinaUku int;
	vrstaRac int;
	kolicinaMIN int;
	kolicinaMAX int;
	kolicinaTab int;
	postoji int;
		BEGIN
		select kolicina into kolicinaUku from Artikli_na_skladistu 
				where Artikli_na_skladistu.id_skladista=new.id_skladista
				and Artikli_na_skladistu.id_artikla=new.id_artikla;
		select count(*) into postoji from narudzbenica
				where narudzbenica.id_skladista=new.id_skladista
				and narudzbenica.id_artikla=new.id_artikla;
		
		kolicinaMIN=10;
		kolicinaMAX=200;
		if postoji=0 then
			if kolicinaUku<kolicinaMIN then
			kolicinaTab=kolicinaMIN-kolicinaUku;
				insert into narudzbenica values (new.id_artikla, new.id_skladista, kolicinaTab,
				'Manjak');
			end if;
			if kolicinaUku>kolicinaMAX then
				kolicinaTab=kolicinaUku-kolicinaMAX;
				insert into narudzbenica values (new.id_artikla, new.id_skladista, kolicinaTab,
				'Visak');
			end if;
		end if;
		if postoji=1 then
			if kolicinaUku<kolicinaMIN then
			kolicinaTab=kolicinaMIN-kolicinaUku;
				Update narudzbenica set kolicina=kolicinaTab, status='Manjak' 
				where new.id_artikla=id_artikla and new.id_skladista=id_skladista;
			end if;
			if kolicinaUku>kolicinaMAX then
				kolicinaTab=kolicinaUku-kolicinaMAX;
				Update narudzbenica set kolicina=kolicinaTab, status='Visak' 
				where new.id_artikla=id_artikla and new.id_skladista=id_skladista;
			end if;
			if kolicinaUku<=kolicinaMAX AND kolicinaUku>=kolicinaMIN then
				delete from narudzbenica where id_artikla=new.id_artikla and id_skladista=new.id_skladista;
			end if;
		end if;
		return new;
		END;
	$$
	LANGUAGE plpgsql;
	
CREATE TRIGGER StrategijaZalihaTr
	After INSERT or UPDATE
	ON Artikli_na_skladistu
	FOR EACH ROW EXECUTE PROCEDURE StrategijaZaliha();	
commit;