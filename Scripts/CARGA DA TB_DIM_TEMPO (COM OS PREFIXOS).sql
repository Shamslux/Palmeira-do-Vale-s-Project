		-------------------------------
		--CARREGANDO A DIMENSÃO TEMPO--
		-------------------------------

		--EXIBINDO A DATA ATUAL

		PRINT CONVERT(VARCHAR,GETDATE(),113) 

		--ALTERANDO O INCREMENTO PARA INÍCIO EM 5000
		--PARA A POSSIBILIDADE DE DATAS ANTERIORES

		DBCC CHECKIDENT (TB_DIM_TEMPO, RESEED, 50000) 

		--INSERÇÃO DE DADOS NA DIMENSÃO

		DECLARE    @DATAINICIO DATETIME 
				 , @DATAFIM DATETIME 
				 , @DATA DATETIME
		 		  
		PRINT GETDATE() 

				SELECT @DATAINICIO = '1/1/1950' 
					, @DATAFIM = '1/1/2050'

				SELECT @DATA = @DATAINICIO 

		WHILE @DATA < @DATAFIM 
		 BEGIN 
	
			INSERT INTO TB_DIM_TEMPO 
			( 
				  DT_DATA, 
				  NM_DIA,
				  NM_DIA_SEMANA, 
				  NM_NUMERO_MES,
				  NM_MES, 
				  NM_QUARTO,
				  NM_NOME_QUARTO, 
				  NM_ANO 
		
			) 
			SELECT @DATA AS DATA, DATEPART(DAY,@DATA) AS NM_DIA, 

				 CASE DATEPART(DW, @DATA) 
            
					WHEN 1 THEN 'Domingo'
					WHEN 2 THEN 'Segunda' 
					WHEN 3 THEN 'Terça' 
					WHEN 4 THEN 'Quarta' 
					WHEN 5 THEN 'Quinta' 
					WHEN 6 THEN 'Sexta' 
					WHEN 7 THEN 'Sábado' 
             
				END AS NM_DIA_SEMANA,

				 DATEPART(MONTH,@DATA) AS NM_MES, 

				 CASE DATENAME(MONTH,@DATA) 
			
					WHEN 'January' THEN 'Janeiro'
					WHEN 'February' THEN 'Fevereiro'
					WHEN 'March' THEN 'Março'
					WHEN 'April' THEN 'Abril'
					WHEN 'May' THEN 'Maio'
					WHEN 'June' THEN 'Junho'
					WHEN 'July' THEN 'Julho'
					WHEN 'August' THEN 'Agosto'
					WHEN 'September' THEN 'Setembro'
					WHEN 'October' THEN 'Outubro'
					WHEN 'November' THEN 'Novembro'
					WHEN 'December' THEN 'Dezembro'
		
				END AS NM_NOME_MES,
		 
				 DATEPART(qq,@DATA) NM_QUARTO, 

				 CASE DATEPART(qq,@DATA) 
					WHEN 1 THEN 'Primeiro' 
					WHEN 2 THEN 'Segundo' 
					WHEN 3 THEN 'Terceiro' 
					WHEN 4 THEN 'Quarto' 
				END AS NM_NOME_QUARTO 
				, DATEPART(YEAR,@DATA) NM_ANO
	
			SELECT @DATA = DATEADD(dd,1,@DATA)
		END

		UPDATE TB_DIM_TEMPO 
		SET NM_DIA = '0' + NM_DIA 
		WHERE LEN(NM_DIA) = 1 

		UPDATE TB_DIM_TEMPO 
		SET NM_NUMERO_MES = '0' + NM_NUMERO_MES 
		WHERE LEN(NM_NUMERO_MES) = 1 

		UPDATE TB_DIM_TEMPO 
		SET DT_DATA_COMPLETA = NM_ANO + NM_NUMERO_MES + NM_DIA 
		GO


		SELECT * FROM TB_DIM_TEMPO
		GO


		----------------------------------------------
		----------FINS DE SEMANA E ESTAÇÕES-----------
		----------------------------------------------

		DECLARE C_TEMPO CURSOR FOR	
			SELECT SK_TEMPO, DT_DATA_COMPLETA, NM_DIA_SEMANA, NM_ANO FROM TB_DIM_TEMPO
		DECLARE			
					@ID INT,
					@DATA varchar(10),
					@DIASEMANA VARCHAR(20),
					@ANO CHAR(4),
					@FIMSEMANA CHAR(3),
					@ESTACAO VARCHAR(15)
					
		OPEN C_TEMPO
			FETCH NEXT FROM C_TEMPO
			INTO @ID, @DATA, @DIASEMANA, @ANO
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
					 IF @DIASEMANA in ('Domingo','Sábado') 
						SET @FIMSEMANA = 'Sim'
					 ELSE 
						SET @FIMSEMANA = 'Não'

					--ATUALIZANDO ESTACOES

					IF @DATA BETWEEN CONVERT(CHAR(4),@ano)+'0923' 
					AND CONVERT(CHAR(4),@ANO)+'1220'
						SET @ESTACAO = 'Primavera'

					ELSE IF @DATA BETWEEN CONVERT(CHAR(4),@ano)+'0321' 
					AND CONVERT(CHAR(4),@ANO)+'0620'
						SET @ESTACAO = 'Outono'

					ELSE IF @DATA BETWEEN CONVERT(CHAR(4),@ano)+'0621' 
					AND CONVERT(CHAR(4),@ANO)+'0922'
						SET @ESTACAO = 'Inverno'

					ELSE -- @data between 21/12 e 20/03
						SET @ESTACAO = 'Verão'

					--ATUALIZANDO FINS DE SEMANA
	
					UPDATE TB_DIM_TEMPO SET NM_FIM_SEMANA = @FIMSEMANA
					WHERE SK_TEMPO = @ID

					--ATUALIZANDO

					UPDATE TB_DIM_TEMPO SET NM_ESTACAO_ANO = @ESTACAO
					WHERE SK_TEMPO = @ID
		
			FETCH NEXT FROM C_TEMPO
			INTO @ID, @DATA, @DIASEMANA, @ANO	
		END
		CLOSE C_TEMPO
		DEALLOCATE C_TEMPO
		GO