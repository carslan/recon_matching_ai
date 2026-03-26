-- step_id: 1 | rule_id: EXCL_CUST_DERIV | operator: exclude_by_predicates
INSERT INTO matched_records (match_group_id, side, statement_id, record_id, rule_id, step_id, operator)
            SELECT
                'EXCL_' || record_id AS match_group_id,
                side, statement_id, record_id,
                'EXCL_CUST_DERIV', 1, 'exclude_by_predicates'
            FROM pool_unmatched
            WHERE side = 'A' AND (ext_asset_info_null_safe IN ('FUT', 'OPT', 'BKL', 'BFW', 'FRA', 'RP', 'RVRP', 'TRP', 'RTRP') AND sec_type_null_safe NOT IN ('MUNI', 'GOVT', 'CD', 'AGENCY', 'CORP'))
        

            INSERT INTO matched_records (match_group_id, side, statement_id, record_id, rule_id, step_id, operator)
            SELECT
                'EXCL_' || record_id AS match_group_id,
                side, statement_id, record_id,
                'EXCL_CUST_DERIV', 1, 'exclude_by_predicates'
            FROM pool_unmatched
            WHERE side = 'B' AND (ext_asset_info_null_safe IN ('FUT', 'OPT', 'BKL', 'BFW', 'FRA', 'RP', 'RVRP', 'TRP', 'RTRP') AND sec_type_null_safe NOT IN ('MUNI', 'GOVT', 'CD', 'AGENCY', 'CORP'))

-- step_id: 2 | rule_id: EXCL_COLLATERAL | operator: exclude_by_predicates
INSERT INTO matched_records (match_group_id, side, statement_id, record_id, rule_id, step_id, operator)
            SELECT
                'EXCL_' || record_id AS match_group_id,
                side, statement_id, record_id,
                'EXCL_COLLATERAL', 2, 'exclude_by_predicates'
            FROM pool_unmatched
            WHERE side = 'A' AND (sec_group == 'CASH' AND sec_type_null_safe == 'COLLATERAL')
        

            INSERT INTO matched_records (match_group_id, side, statement_id, record_id, rule_id, step_id, operator)
            SELECT
                'EXCL_' || record_id AS match_group_id,
                side, statement_id, record_id,
                'EXCL_COLLATERAL', 2, 'exclude_by_predicates'
            FROM pool_unmatched
            WHERE side = 'B' AND (sec_group == 'CASH' AND sec_type_null_safe == 'COLLATERAL')

-- step_id: 3 | rule_id: EXCL_FX_HEDGE | operator: exclude_by_predicates
INSERT INTO matched_records (match_group_id, side, statement_id, record_id, rule_id, step_id, operator)
            SELECT
                'EXCL_' || record_id AS match_group_id,
                side, statement_id, record_id,
                'EXCL_FX_HEDGE', 3, 'exclude_by_predicates'
            FROM pool_unmatched
            WHERE side = 'A' AND (sec_group == 'FX' AND type == 'HEDGE')

-- step_id: 4 | rule_id: EXACT_MATCH_FUND | operator: one_to_one_ranked
WITH candidates AS (
            SELECT
                a.record_id AS a_record_id, a.side AS a_side, a.statement_id AS a_statement_id,
                b.record_id AS b_record_id, b.side AS b_side, b.statement_id AS b_statement_id,
                ABS(CAST(a.orig_face AS DOUBLE) - CAST(b.orig_face AS DOUBLE)) AS match_score,
                ROW_NUMBER() OVER (PARTITION BY a.record_id ORDER BY ABS(CAST(a.orig_face AS DOUBLE) - CAST(b.orig_face AS DOUBLE)), b.record_id) AS rank_for_a,
                ROW_NUMBER() OVER (PARTITION BY b.record_id ORDER BY ABS(CAST(a.orig_face AS DOUBLE) - CAST(b.orig_face AS DOUBLE)), a.record_id) AS rank_for_b
            FROM pool_unmatched a
            JOIN pool_unmatched b ON a.side = 'A' AND b.side = 'B'
                AND a.blk_cusip = b.blk_cusip
            WHERE ((a.sec_group == 'FUND')) AND ((b.sec_group == 'FUND'))
                AND ABS(CAST(a.orig_face AS DOUBLE) - CAST(b.orig_face AS DOUBLE)) < 0.01
        ),
        mutual_best AS (
            SELECT * FROM candidates WHERE rank_for_a = 1 AND rank_for_b = 1
        )
        SELECT a_record_id, a_side, a_statement_id, b_record_id, b_side, b_statement_id, match_score
        FROM mutual_best

-- step_id: 5 | rule_id: EXACT_MATCH_BLKCUSIP | operator: one_to_one_ranked
WITH candidates AS (
            SELECT
                a.record_id AS a_record_id, a.side AS a_side, a.statement_id AS a_statement_id,
                b.record_id AS b_record_id, b.side AS b_side, b.statement_id AS b_statement_id,
                ABS(CAST(a.orig_face AS DOUBLE) - CAST(b.orig_face AS DOUBLE)) AS match_score,
                ROW_NUMBER() OVER (PARTITION BY a.record_id ORDER BY ABS(CAST(a.orig_face AS DOUBLE) - CAST(b.orig_face AS DOUBLE)), b.record_id) AS rank_for_a,
                ROW_NUMBER() OVER (PARTITION BY b.record_id ORDER BY ABS(CAST(a.orig_face AS DOUBLE) - CAST(b.orig_face AS DOUBLE)), a.record_id) AS rank_for_b
            FROM pool_unmatched a
            JOIN pool_unmatched b ON a.side = 'A' AND b.side = 'B'
                AND a.blk_cusip = b.blk_cusip
            WHERE (1=1) AND (1=1)
                AND ABS(CAST(a.orig_face AS DOUBLE) - CAST(b.orig_face AS DOUBLE)) <= 0.005
        ),
        mutual_best AS (
            SELECT * FROM candidates WHERE rank_for_a = 1 AND rank_for_b = 1
        )
        SELECT a_record_id, a_side, a_statement_id, b_record_id, b_side, b_statement_id, match_score
        FROM mutual_best

-- step_id: 6 | rule_id: SEC_ID_ISSUE_MULTI | operator: many_to_many_balance_k
WITH side_a_agg AS (
            SELECT blk_cusip, COALESCE(SUM(CAST(orig_face AS DOUBLE)), 0) AS agg_orig_face
            FROM pool_unmatched a WHERE side = 'A' AND ((((source IN ('S', 'B')) AND (ref_entity == 'Multiple')) OR (source == 'P')))
            GROUP BY blk_cusip
        ),
        side_b_agg AS (
            SELECT blk_cusip, COALESCE(SUM(CAST(orig_face AS DOUBLE)), 0) AS agg_orig_face
            FROM pool_unmatched b WHERE side = 'B' AND ((((source IN ('S', 'B')) AND (ref_entity == 'Multiple')) OR (source == 'P')))
            GROUP BY blk_cusip
        ),
        balanced_blocks AS (
            SELECT sa.blk_cusip AS block_key
            FROM side_a_agg sa
            JOIN side_b_agg sb ON sa.blk_cusip = sb.blk_cusip
            WHERE ABS(sa.agg_orig_face - sb.agg_orig_face) < 0.001
        )
        SELECT block_key FROM balanced_blocks

-- step_id: 7 | rule_id: ZERO_POS | operator: one_sided
WITH block_sums AS (
            SELECT blk_cusip,
                   COALESCE(SUM(CAST(orig_face AS DOUBLE)), 0) AS total,
                   COUNT(*) AS cnt
            FROM pool_unmatched
            WHERE side = 'A' AND (1=1)
            GROUP BY blk_cusip
            HAVING cnt >= 2 AND ABS(COALESCE(SUM(CAST(orig_face AS DOUBLE)), 0)) <= 0.0
        )
        SELECT blk_cusip FROM block_sums

