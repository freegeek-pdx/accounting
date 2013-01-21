INSERT INTO trialbal(trialbal_accnt_id, trialbal_period_id, trialbal_beginning, trialbal_ending, trialbal_credits, trialbal_debits, trialbal_dirty) SELECT accnt_id, period_id, 0.00, 0.00, 0.00, 0.00, 't' FROM accnt JOIN period ON 1=1 LEFT OUTER JOIN trialbal ON accnt_id = trialbal_accnt_id AND period_id = trialbal_period_id WHERE trialbal_id IS NULL;
UPDATE trialbal SET trialbal_credits = (SELECT COALESCE(SUM(CASE WHEN gltrans_amount > 0 THEN gltrans_amount ELSE 0 END), 0.00) FROM gltrans WHERE period_start <= gltrans_date AND period_end >= gltrans_date AND gltrans_accnt_id = trialbal_accnt_id AND gltrans_deleted = 'f'), trialbal_debits = (SELECT COALESCE(SUM(CASE WHEN gltrans_amount < 0 THEN -1 * gltrans_amount ELSE 0 END), 0.00) FROM gltrans WHERE period_start <= gltrans_date AND period_end >= gltrans_date AND gltrans_accnt_id = trialbal_accnt_id AND gltrans_deleted = 'f') FROM period WHERE period_id = trialbal_period_id;
UPDATE trialbal SET trialbal_beginning = 0, trialbal_ending = trialbal_credits - trialbal_debits, trialbal_dirty = 't';