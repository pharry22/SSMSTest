      alter function PA_IPOS_GET_APPROVERS(@IN_SUN_DB nvarchar(3), @IN_MATRIX_TYPE nvarchar(1), @IN_DOC_NO numeric(10),
                                            @IN_DOC_LINE_NO numeric(10), @IN_DOC_SPLIT_LINE_NO numeric(10), @IN_EXCEPTION_AUTHORITY nvarchar(1),
                                            @IN_NEXT_LEVEL nvarchar(1)) returns nvarchar(4000) as
        -- @IN_MATRIX_TYPE should be R for Requisitions

        -- @IN_EXCEPTION_AUTHORITY should be Y for only Exection Authority
        -- @IN_EXCEPTION_AUTHORITY should be N for non Exection Authority
        -- @IN_EXCEPTION_AUTHORITY should be B for both (i.e if normal approver is not found then approvers with exection authority will be returned
      begin
        declare
          @excep_auth    nvarchar(1),
          @row_no        numeric(10),
          @line_no       numeric(10),
          @app_grp_id1   nvarchar(500),
          @app_grp_id2   nvarchar(500),
          @app_grp_id3   nvarchar(500),
          @app_grp_id4   nvarchar(500),
          @app_grp_id5   nvarchar(500),
          @app_grp_id6   nvarchar(500),
          @approver      nvarchar(500),
          @next_approver nvarchar(4000),
          @purc_accnt    nvarchar(15),
          @doc_status    nvarchar(1),
          @doc_amt       numeric(20,5),
          @fld_tcode1    nvarchar(15),
          @fld_tcode2    nvarchar(15),
          @fld_tcode3    nvarchar(15),
          @fld_tcode4    nvarchar(15),
          @fld_tcode5    nvarchar(15),
          @fld_tcode6    nvarchar(15),
          @fld_tcode7    nvarchar(15),
          @fld_tcode8    nvarchar(15),
          @fld_tcode9    nvarchar(15),
          @fld_tcode10   nvarchar(15),
          @fld_qcode1    nvarchar(15),
          @fld_qcode2    nvarchar(15),
          @fld_qcode3    nvarchar(15),
          @fld_qcode4    nvarchar(15),
          @fld_qcode5    nvarchar(15),
          @fld_qcode6    nvarchar(15),
          @fld_qcode7    nvarchar(15),
          @fld_qcode8    nvarchar(15),
          @fld_qcode9    nvarchar(15),
          @fld_qcode10   nvarchar(15),
          @fld_amt_chk   nvarchar(1),
          @doc_tcode0    nvarchar(15),
          @doc_tcode1    nvarchar(15),
          @doc_tcode2    nvarchar(15),
          @doc_tcode3    nvarchar(15),
          @doc_tcode4    nvarchar(15),
          @doc_tcode5    nvarchar(15),
          @doc_tcode6    nvarchar(15),
          @doc_tcode7    nvarchar(15),
          @doc_tcode8    nvarchar(15),
          @doc_tcode9    nvarchar(15),
          @doc_qcode0    nvarchar(15),
          @doc_qcode1    nvarchar(15),
          @doc_qcode2    nvarchar(15),
          @doc_qcode3    nvarchar(15),
          @doc_qcode4    nvarchar(15),
          @doc_qcode5    nvarchar(15),
          @doc_qcode6    nvarchar(15),
          @doc_qcode7    nvarchar(15),
          @doc_qcode8    nvarchar(15),
          @doc_qcode9    nvarchar(15),
          @doc_qcode10   nvarchar(15),
          @doc_qcode11   nvarchar(15),
          @doc_qcode12   nvarchar(15),
          @doc_qcode13   nvarchar(15),
          @doc_qcode14   nvarchar(15),
          @doc_qcode15   nvarchar(15),
          @doc_qcode16   nvarchar(15),
          @doc_qcode17   nvarchar(15),
          @doc_qcode18   nvarchar(15),
          @doc_qcode19   nvarchar(15),
          @tcode_val1    nvarchar(15),
          @tcode_val2    nvarchar(15),
          @tcode_val3    nvarchar(15),
          @tcode_val4    nvarchar(15),
          @tcode_val5    nvarchar(15),
          @tcode_val6    nvarchar(15),
          @tcode_val7    nvarchar(15),
          @tcode_val8    nvarchar(15),
          @tcode_val9    nvarchar(15),
          @tcode_val10   nvarchar(15),
          @qcode_val1    nvarchar(15),
          @qcode_val2    nvarchar(15),
          @qcode_val3    nvarchar(15),
          @qcode_val4    nvarchar(15),
          @qcode_val5    nvarchar(15),
          @qcode_val6    nvarchar(15),
          @qcode_val7    nvarchar(15),
          @qcode_val8    nvarchar(15),
          @qcode_val9    nvarchar(15),
          @qcode_val10   nvarchar(15),
          @app_by_1      nvarchar(500),
          @app_by_2      nvarchar(500),
          @app_by_3      nvarchar(500),
          @app_by_4      nvarchar(500),
          @app_by_5      nvarchar(500),
          @app_by_6      nvarchar(500),
          @lvl           int,
          @next_lvl      int,
          @lvl_found     int,
          @dt            datetime,
          @doc_type      nvarchar(1),
          @normal_app    nvarchar(1),
          @header_str    nvarchar(7),
          @submitted_by_guid  nvarchar(36)  -- guid stored in table


        declare @tmp_table table (APPROVER nvarchar(500))

        if @IN_MATRIX_TYPE = 'I'
          select @doc_type = (case rtrim(isnull(INV_TYPE,'')) when ' ' then 'I' else 'C' end)
          from PA_REQ_INVOICES with (nolock)
          where SUN_DB = rtrim(@IN_SUN_DB) and INV_NO = @IN_DOC_NO
        else
          select @doc_type = ' '

        set @header_str = '';
        if @IN_MATRIX_TYPE = 'H'
          set @header_str = 'header '

        select @fld_tcode1 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 1',  2),
               @fld_tcode2 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 2',  2),
               @fld_tcode3 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 3',  2),
               @fld_tcode4 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 4',  2),
               @fld_tcode5 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 5',  2),
               @fld_tcode6 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 6',  2),
               @fld_tcode7 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 7',  2),
               @fld_tcode8 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 8',  2),
               @fld_tcode9 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 9',  2),
               @fld_tcode10 = dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 't cat 10', 2),
               @fld_qcode1 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 1',  3),
               @fld_qcode2 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 2',  3),
               @fld_qcode3 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 3',  3),
               @fld_qcode4 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 4',  3),
               @fld_qcode5 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 5',  3),
               @fld_qcode6 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 6',  3),
               @fld_qcode7 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 7',  3),
               @fld_qcode8 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 8',  3),
               @fld_qcode9 =  dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 9',  3),
               @fld_qcode10 = dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', @header_str + 'q cat 10', 3),
               @fld_amt_chk = dbo.PA_REQ_SYSTEM_PROFILE_FN(@IN_SUN_DB, 'approvals', 'gross amounts', 1)

        -- make sure that nulls and blank spaces are removed to make it easier to compare it in the where clause
        select @fld_tcode1 =  rtrim(isnull(@fld_tcode1,'')),
               @fld_tcode2 =  rtrim(isnull(@fld_tcode2,'')),
               @fld_tcode3 =  rtrim(isnull(@fld_tcode3,'')),
               @fld_tcode4 =  rtrim(isnull(@fld_tcode4,'')),
               @fld_tcode5 =  rtrim(isnull(@fld_tcode5,'')),
               @fld_tcode6 =  rtrim(isnull(@fld_tcode6,'')),
               @fld_tcode7 =  rtrim(isnull(@fld_tcode7,'')),
               @fld_tcode8 =  rtrim(isnull(@fld_tcode8,'')),
               @fld_tcode9 =  rtrim(isnull(@fld_tcode9,'')),
               @fld_tcode10 = rtrim(isnull(@fld_tcode10,'')),
               @fld_qcode1 =  rtrim(isnull(@fld_qcode1,'')),
               @fld_qcode2 =  rtrim(isnull(@fld_qcode2,'')),
               @fld_qcode3 =  rtrim(isnull(@fld_qcode3,'')),
               @fld_qcode4 =  rtrim(isnull(@fld_qcode4,'')),
               @fld_qcode5 =  rtrim(isnull(@fld_qcode5,'')),
               @fld_qcode6 =  rtrim(isnull(@fld_qcode6,'')),
               @fld_qcode7 =  rtrim(isnull(@fld_qcode7,'')),
               @fld_qcode8 =  rtrim(isnull(@fld_qcode8,'')),
               @fld_qcode9 =  rtrim(isnull(@fld_qcode9,'')),
               @fld_qcode10 = rtrim(isnull(@fld_qcode10,''))

        if @IN_MATRIX_TYPE = 'I'
          select @purc_accnt = i.PURCHASE_ACCNT_CODE,
                 @doc_amt = case @fld_amt_chk when 'Y' then i.VALUE else i.VALUE-i.TAX_VALUE end,
                 @doc_tcode0 = i.ANAL_T0, @doc_tcode1 = i.ANAL_T1, @doc_tcode2 = i.ANAL_T2,
                 @doc_tcode3 = i.ANAL_T3, @doc_tcode4 = i.ANAL_T4, @doc_tcode5 = i.ANAL_T5, @doc_tcode6 = i.ANAL_T6,
                 @doc_tcode7 = i.ANAL_T7, @doc_tcode8 = i.ANAL_T8, @doc_tcode9 = i.ANAL_T9, @lvl = case when i.APPROVAL_LEVEL < 0 then 0 else i.APPROVAL_LEVEL end,
                 @doc_qcode0 = case i.IS_POUT when 'Y' then p.ANAL_Q00 else q.ANAL_Q00 end,
                 @doc_qcode1 = case i.IS_POUT when 'Y' then p.ANAL_Q01 else q.ANAL_Q01 end,
                 @doc_qcode2 = case i.IS_POUT when 'Y' then p.ANAL_Q02 else q.ANAL_Q02 end,
                 @doc_qcode3 = case i.IS_POUT when 'Y' then p.ANAL_Q03 else q.ANAL_Q03 end,
                 @doc_qcode4 = case i.IS_POUT when 'Y' then p.ANAL_Q04 else q.ANAL_Q04 end,
                 @doc_qcode5 = case i.IS_POUT when 'Y' then p.ANAL_Q05 else q.ANAL_Q05 end,
                 @doc_qcode6 = case i.IS_POUT when 'Y' then p.ANAL_Q06 else q.ANAL_Q06 end,
                 @doc_qcode7 = case i.IS_POUT when 'Y' then p.ANAL_Q07 else q.ANAL_Q07 end,
                 @doc_qcode8 = case i.IS_POUT when 'Y' then p.ANAL_Q08 else q.ANAL_Q08 end,
                 @doc_qcode9 = case i.IS_POUT when 'Y' then p.ANAL_Q09 else q.ANAL_Q09 end,
                 @doc_qcode10= case i.IS_POUT when 'Y' then p.ANAL_Q10 else q.ANAL_Q10 end,
                 @doc_qcode11= case i.IS_POUT when 'Y' then p.ANAL_Q11 else q.ANAL_Q11 end,
                 @doc_qcode12= case i.IS_POUT when 'Y' then p.ANAL_Q12 else q.ANAL_Q12 end,
                 @doc_qcode13= case i.IS_POUT when 'Y' then p.ANAL_Q13 else q.ANAL_Q13 end,
                 @doc_qcode14= case i.IS_POUT when 'Y' then p.ANAL_Q14 else q.ANAL_Q14 end,
                 @doc_qcode15= case i.IS_POUT when 'Y' then p.ANAL_Q15 else q.ANAL_Q15 end,
                 @doc_qcode16= case i.IS_POUT when 'Y' then p.ANAL_Q16 else q.ANAL_Q16 end,
                 @doc_qcode17= case i.IS_POUT when 'Y' then p.ANAL_Q17 else q.ANAL_Q17 end,
                 @doc_qcode18= case i.IS_POUT when 'Y' then p.ANAL_Q18 else q.ANAL_Q18 end,
                 @doc_qcode19= case i.IS_POUT when 'Y' then p.ANAL_Q19 else q.ANAL_Q19 end,
                 @doc_status = i.INV_LINE_STATUS, @app_by_1 = i.APPROVED_BY_1, @app_by_2 = i.APPROVED_BY_2, @app_by_3 = i.APPROVED_BY_3,
                 @app_by_4 = i.APPROVED_BY_4, @app_by_5 = i.APPROVED_BY_5, @app_by_6 = i.APPROVED_BY_6
          from PA_REQ_INVOICE_ITEMS i with (nolock)
            left join PA_REQ_ITEMS q with (nolock) on (i.SUN_DB = q.SUN_DB and i.ITEM_CODE = q.ITEM_CODE)
            left join PA_REQ_POUT_DEFAULTS p with (nolock) on (i.SUN_DB = p.SUN_DB and i.UNSPSC between p.UNSPSC_FROM and p.UNSPSC_TO and i.IS_POUT = 'Y')
          where i.SUN_DB = @IN_SUN_DB
            and i.INV_NO = @IN_DOC_NO
            and i.INV_LINE_NO = @IN_DOC_LINE_NO
        else if @IN_MATRIX_TYPE = 'H'
          select @purc_accnt = null,
                 @doc_amt = case @fld_amt_chk when 'Y' then h.TOTAL_VALUE else h.TOTAL_VALUE-h.TOTAL_TAX_VALUE end,
                 @doc_tcode0 = d.ANAL_T0, @doc_tcode1 = d.ANAL_T1, @doc_tcode2 = d.ANAL_T2,
                 @doc_tcode3 = d.ANAL_T3, @doc_tcode4 = d.ANAL_T4, @doc_tcode5 = d.ANAL_T5, @doc_tcode6 = d.ANAL_T6,
                 @doc_tcode7 = d.ANAL_T7, @doc_tcode8 = d.ANAL_T8, @doc_tcode9 = d.ANAL_T9, @lvl = case when h.APPROVAL_LEVEL < 0 then 1 else h.APPROVAL_LEVEL end,
                 @doc_qcode0 = null, @doc_qcode1 = null, @doc_qcode2 = null, @doc_qcode3 = null,
                 @doc_qcode4 = null, @doc_qcode5 = null, @doc_qcode6 = null, @doc_qcode7 = null,
                 @doc_qcode8 = null, @doc_qcode9 = null, @doc_qcode10= null, @doc_qcode11= null,
                 @doc_qcode12= null, @doc_qcode13= null, @doc_qcode14= null, @doc_qcode15= null,
                 @doc_qcode16= null, @doc_qcode17= null, @doc_qcode18= null, @doc_qcode19= null,
                 @doc_status = h.STATUS, @app_by_1 = h.APPROVED_BY_1, @app_by_2 = h.APPROVED_BY_2, @app_by_3 = h.APPROVED_BY_3,
                 @app_by_4 = h.APPROVED_BY_4, @app_by_5 = h.APPROVED_BY_5, @app_by_6 = h.APPROVED_BY_6,
                 @submitted_by_guid = h.SUBMITTED_BY
          from PA_REQ_REQUISITIONS_HDR h with (nolock)
            inner join PA_REQ_REQUISITIONS_HDR_DIST d with (nolock) on (h.SUN_DB = d.SUN_DB and h.REQ_NO = d.REQ_NO and d.DIST_TYPE = 'H')
          where h.SUN_DB = @IN_SUN_DB
            and h.REQ_NO = @IN_DOC_NO
        else
          select @purc_accnt = i.PURCHASE_ACCNT_CODE,
                 @doc_amt = case @fld_amt_chk when 'Y' then i.VALUE else i.VALUE-i.TAX_VALUE end,
                 @doc_tcode0 = i.ANAL_T0, @doc_tcode1 = i.ANAL_T1, @doc_tcode2 = i.ANAL_T2,
                 @doc_tcode3 = i.ANAL_T3, @doc_tcode4 = i.ANAL_T4, @doc_tcode5 = i.ANAL_T5, @doc_tcode6 = i.ANAL_T6,
                 @doc_tcode7 = i.ANAL_T7, @doc_tcode8 = i.ANAL_T8, @doc_tcode9 = i.ANAL_T9, @lvl = case when i.APPROVAL_LEVEL < 0 then 1 else i.APPROVAL_LEVEL end,
                 @doc_qcode0 = case i.REQ_TYPE when 'P' then p.ANAL_Q00 else q.ANAL_Q00 end,
                 @doc_qcode1 = case i.REQ_TYPE when 'P' then p.ANAL_Q01 else q.ANAL_Q01 end,
                 @doc_qcode2 = case i.REQ_TYPE when 'P' then p.ANAL_Q02 else q.ANAL_Q02 end,
                 @doc_qcode3 = case i.REQ_TYPE when 'P' then p.ANAL_Q03 else q.ANAL_Q03 end,
                 @doc_qcode4 = case i.REQ_TYPE when 'P' then p.ANAL_Q04 else q.ANAL_Q04 end,
                 @doc_qcode5 = case i.REQ_TYPE when 'P' then p.ANAL_Q05 else q.ANAL_Q05 end,
                 @doc_qcode6 = case i.REQ_TYPE when 'P' then p.ANAL_Q06 else q.ANAL_Q06 end,
                 @doc_qcode7 = case i.REQ_TYPE when 'P' then p.ANAL_Q07 else q.ANAL_Q07 end,
                 @doc_qcode8 = case i.REQ_TYPE when 'P' then p.ANAL_Q08 else q.ANAL_Q08 end,
                 @doc_qcode9 = case i.REQ_TYPE when 'P' then p.ANAL_Q09 else q.ANAL_Q09 end,
                 @doc_qcode10= case i.REQ_TYPE when 'P' then p.ANAL_Q10 else q.ANAL_Q10 end,
                 @doc_qcode11= case i.REQ_TYPE when 'P' then p.ANAL_Q11 else q.ANAL_Q11 end,
                 @doc_qcode12= case i.REQ_TYPE when 'P' then p.ANAL_Q12 else q.ANAL_Q12 end,
                 @doc_qcode13= case i.REQ_TYPE when 'P' then p.ANAL_Q13 else q.ANAL_Q13 end,
                 @doc_qcode14= case i.REQ_TYPE when 'P' then p.ANAL_Q14 else q.ANAL_Q14 end,
                 @doc_qcode15= case i.REQ_TYPE when 'P' then p.ANAL_Q15 else q.ANAL_Q15 end,
                 @doc_qcode16= case i.REQ_TYPE when 'P' then p.ANAL_Q16 else q.ANAL_Q16 end,
                 @doc_qcode17= case i.REQ_TYPE when 'P' then p.ANAL_Q17 else q.ANAL_Q17 end,
                 @doc_qcode18= case i.REQ_TYPE when 'P' then p.ANAL_Q18 else q.ANAL_Q18 end,
                 @doc_qcode19= case i.REQ_TYPE when 'P' then p.ANAL_Q19 else q.ANAL_Q19 end,
                 @doc_status = i.REQ_LINE_STATUS, @app_by_1 = i.APPROVED_BY_1, @app_by_2 = i.APPROVED_BY_2, @app_by_3 = i.APPROVED_BY_3,
                 @app_by_4 = i.APPROVED_BY_4, @app_by_5 = i.APPROVED_BY_5, @app_by_6 = i.APPROVED_BY_6,
                 @submitted_by_guid = i.SUBMITTED_BY
          from PA_REQ_REQUISITIONS i with (nolock)
            left join PA_REQ_ITEMS q with (nolock) on (i.SUN_DB = q.SUN_DB and i.ITEM_CODE = q.ITEM_CODE)
            left join PA_REQ_POUT_DEFAULTS p with (nolock) on (i.SUN_DB = p.SUN_DB and i.UNSPSC between p.UNSPSC_FROM and p.UNSPSC_TO and i.REQ_TYPE = 'P')
          where i.SUN_DB = @IN_SUN_DB
            and i.REQ_NO = @IN_DOC_NO
            and i.REQ_LINE_NO = @IN_DOC_LINE_NO
            and i.REQ_SPLIT_LINE_NO = @IN_DOC_SPLIT_LINE_NO

        set @next_lvl = 0
        set @lvl_found = -1;

        if @doc_status = 'D'
          set @lvl = -8
        else if @doc_status = 'U'
          set @lvl = -9

        -- check ANAL_T1 in range
        select @tcode_val1  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode1,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val2  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode2,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val3  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode3,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val4  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode4,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val5  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode5,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val6  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode6,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val7  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode7,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val8  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode8,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val9  = dbo.PA_IPOS_GET_DOC_T(@fld_tcode9,  @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @tcode_val10 = dbo.PA_IPOS_GET_DOC_T(@fld_tcode10, @doc_tcode0,  @doc_tcode1,  @doc_tcode2,  @doc_tcode3,  @doc_tcode4,  @doc_tcode5,  @doc_tcode6,  @doc_tcode7,  @doc_tcode8,  @doc_tcode9),
               @qcode_val1  = dbo.PA_IPOS_GET_DOC_Q(@fld_qcode1,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val2  = dbo.PA_IPOS_GET_DOC_Q(@fld_qcode2,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val3  = dbo.PA_IPOS_GET_DOC_Q(@fld_qcode3,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val4  = dbo.PA_IPOS_GET_DOC_Q(@fld_qcode4,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val5  = dbo.PA_IPOS_GET_DOC_Q(@fld_qcode5,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val6 =  dbo.PA_IPOS_GET_DOC_Q(@fld_qcode6,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val7 =  dbo.PA_IPOS_GET_DOC_Q(@fld_qcode7,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val8 =  dbo.PA_IPOS_GET_DOC_Q(@fld_qcode8,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val9 =  dbo.PA_IPOS_GET_DOC_Q(@fld_qcode9,  @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19),
               @qcode_val10=  dbo.PA_IPOS_GET_DOC_Q(@fld_qcode10, @doc_qcode0,  @doc_qcode1,  @doc_qcode2,  @doc_qcode3,  @doc_qcode4,  @doc_qcode5,  @doc_qcode6,  @doc_qcode7,  @doc_qcode8,  @doc_qcode9,
                                                                  @doc_qcode10, @doc_qcode11, @doc_qcode12, @doc_qcode13, @doc_qcode14, @doc_qcode15, @doc_qcode16, @doc_qcode17, @doc_qcode18, @doc_qcode19)
        if (@lvl >= 0) and (@lvl <= 6)
          begin
            set @next_approver = ''
            set @normal_app = 'N'

            declare app_cursor cursor forward_only static read_only for
            WITH Matrix as  
              (  
                SELECT SUN_DB, MATRIX_TYPE, EXCEPTION_AUTHORITY, ROW_NO, LINE_NO, APPLIES_TO, 
                     isnull(AMOUNT_OP, 'be') as AMOUNT_OP,
                     AMOUNT_VAL1 as ACTUAL_VAL1,
                     AMOUNT_VAL2 as ACTUAL_VAL2,
                     isnull(AMOUNT_VAL1, 0) as AMOUNT_VAL1,
                     isnull(AMOUNT_VAL2, 0) as AMOUNT_VAL2,
                     isnull(ACCNT_CODE_FROM, '') as ACCNT_CODE_FROM, isnull(ACCNT_CODE_TO,'') as ACCNT_CODE_TO, 
                     isnull(T_CODE_FROM_1, '') as T_CODE_FROM_1,     isnull(T_CODE_TO_1, '') as T_CODE_TO_1, 
                     isnull(T_CODE_FROM_2, '') as T_CODE_FROM_2,     isnull(T_CODE_TO_2, '') as T_CODE_TO_2, 
                     isnull(T_CODE_FROM_3, '') as T_CODE_FROM_3,     isnull(T_CODE_TO_3, '') as T_CODE_TO_3, 
                     isnull(T_CODE_FROM_4, '') as T_CODE_FROM_4,     isnull(T_CODE_TO_4, '') as T_CODE_TO_4, 
                     isnull(T_CODE_FROM_5, '') as T_CODE_FROM_5,     isnull(T_CODE_TO_5, '') as T_CODE_TO_5, 
                     isnull(T_CODE_FROM_6, '') as T_CODE_FROM_6,     isnull(T_CODE_TO_6, '') as T_CODE_TO_6, 
                     isnull(T_CODE_FROM_7, '') as T_CODE_FROM_7,     isnull(T_CODE_TO_7, '') as T_CODE_TO_7, 
                     isnull(T_CODE_FROM_8, '') as T_CODE_FROM_8,     isnull(T_CODE_TO_8, '') as T_CODE_TO_8, 
                     isnull(T_CODE_FROM_9, '') as T_CODE_FROM_9,     isnull(T_CODE_TO_9, '') as T_CODE_TO_9, 
                     isnull(T_CODE_FROM_10, '') as T_CODE_FROM_10,   isnull(T_CODE_TO_10, '') as T_CODE_TO_10, 
                     isnull(Q_CODE_FROM_1, '') as Q_CODE_FROM_1,     isnull(Q_CODE_TO_1, '') as Q_CODE_TO_1, 
                     isnull(Q_CODE_FROM_2, '') as Q_CODE_FROM_2,     isnull(Q_CODE_TO_2, '') as Q_CODE_TO_2, 
                     isnull(Q_CODE_FROM_3, '') as Q_CODE_FROM_3,     isnull(Q_CODE_TO_3, '') as Q_CODE_TO_3, 
                     isnull(Q_CODE_FROM_4, '') as Q_CODE_FROM_4,     isnull(Q_CODE_TO_4, '') as Q_CODE_TO_4, 
                     isnull(Q_CODE_FROM_5, '') as Q_CODE_FROM_5,     isnull(Q_CODE_TO_5, '') as Q_CODE_TO_5, 
                     isnull(Q_CODE_FROM_6, '') as Q_CODE_FROM_6,     isnull(Q_CODE_TO_6, '') as Q_CODE_TO_6, 
                     isnull(Q_CODE_FROM_7, '') as Q_CODE_FROM_7,     isnull(Q_CODE_TO_7, '') as Q_CODE_TO_7, 
                     isnull(Q_CODE_FROM_8, '') as Q_CODE_FROM_8,     isnull(Q_CODE_TO_8, '') as Q_CODE_TO_8, 
                     isnull(Q_CODE_FROM_9, '') as Q_CODE_FROM_9,     isnull(Q_CODE_TO_9, '') as Q_CODE_TO_9, 
                     isnull(Q_CODE_FROM_10, '') as Q_CODE_FROM_10,   isnull(Q_CODE_TO_10, '') as Q_CODE_TO_10,
                     APPROVER_1, APPROVER_2, APPROVER_3, APPROVER_4, APPROVER_5, APPROVER_6
                from PA_REQ_APPROVAL_MATRIX_HELPER  with (nolock) 
                where SUN_DB = @IN_SUN_DB
                  and MATRIX_TYPE = @IN_MATRIX_TYPE
                  and APPLIES_TO in (' ', @doc_type)
            )
            Select m.EXCEPTION_AUTHORITY, m.ROW_NO, m.LINE_NO,
                   m.APPROVER_1, m.APPROVER_2, m.APPROVER_3, 
                   m.APPROVER_4, m.APPROVER_5, m.APPROVER_6
            from Matrix m with (nolock)
            where ( (@purc_accnt between ACCNT_CODE_FROM and ACCNT_CODE_TO) or 
                    (@purc_accnt = ACCNT_CODE_FROM and ACCNT_CODE_TO = '') or 
                    (@purc_accnt = ACCNT_CODE_TO and ACCNT_CODE_FROM = '') or 
                    (ACCNT_CODE_FROM = '' and ACCNT_CODE_TO = '') )
              -- Amount
              and ( ( (ACTUAL_VAL1 is null and ACTUAL_VAL2 is null) or (AMOUNT_OP = 'be' and ACTUAL_VAL1 is null) ) or
                    (AMOUNT_OP = 'be' and @doc_amt between AMOUNT_VAL1 and AMOUNT_VAL2) or
                    (AMOUNT_OP = '=' and @doc_amt = AMOUNT_VAL1) or
                    (AMOUNT_OP = '>' and @doc_amt > AMOUNT_VAL1) or
                    (AMOUNT_OP = '>=' and @doc_amt >= AMOUNT_VAL1) or
                    (AMOUNT_OP = '<' and @doc_amt < AMOUNT_VAL1) or
                    (AMOUNT_OP = '<=' and @doc_amt <= AMOUNT_VAL1) )
              -- tcode 1 ranges
              and (@fld_tcode1 = '' or @tcode_val1 = '' or 
                   (@tcode_val1 between T_CODE_FROM_1 and T_CODE_TO_1) or 
                   (@tcode_val1 = T_CODE_FROM_1 and T_CODE_TO_1 = '') or 
                   (@tcode_val1 = T_CODE_TO_1 and T_CODE_FROM_1 = '') or 
                   (T_CODE_FROM_1 = '' and T_CODE_TO_1 = '') )
              -- tcode 2 ranges
              and (@fld_tcode2 = '' or @tcode_val2 = '' or 
                   (@tcode_val2 between T_CODE_FROM_2 and T_CODE_TO_2) or 
                   (@tcode_val2 = T_CODE_FROM_2 and T_CODE_TO_2 = '') or 
                   (@tcode_val2 = T_CODE_TO_2 and T_CODE_FROM_2 = '') or 
                   (T_CODE_FROM_2 = '' and T_CODE_TO_2 = '') )
              -- tcode 3 ranges
              and (@fld_tcode3 = '' or @tcode_val3 = '' or 
                   (@tcode_val3 between T_CODE_FROM_3 and T_CODE_TO_3) or 
                   (@tcode_val3 = T_CODE_FROM_3 and T_CODE_TO_3 = '') or 
                   (@tcode_val3 = T_CODE_TO_3 and T_CODE_FROM_3 = '') or 
                   (T_CODE_FROM_3 = '' and T_CODE_TO_3 = '') )
              -- tcode 4 ranges
              and (@fld_tcode4 = '' or @tcode_val4 = '' or 
                   (@tcode_val4 between T_CODE_FROM_4 and T_CODE_TO_4) or 
                   (@tcode_val4 = T_CODE_FROM_4 and T_CODE_TO_4 = '') or 
                   (@tcode_val4 = T_CODE_TO_4 and T_CODE_FROM_4 = '') or 
                   (T_CODE_FROM_4 = '' and T_CODE_TO_4 = '') )
              -- tcode 5 ranges
              and (@fld_tcode5 = '' or @tcode_val5 = '' or 
                   (@tcode_val5 between T_CODE_FROM_5 and T_CODE_TO_5) or 
                   (@tcode_val5 = T_CODE_FROM_5 and T_CODE_TO_5 = '') or 
                   (@tcode_val5 = T_CODE_TO_5 and T_CODE_FROM_5 = '') or 
                   (T_CODE_FROM_5 = '' and T_CODE_TO_5 = '') )
              -- tcode 6 ranges
              and (@fld_tcode6 = '' or @tcode_val6 = '' or 
                   (@tcode_val6 between T_CODE_FROM_6 and T_CODE_TO_6) or 
                   (@tcode_val6 = T_CODE_FROM_6 and T_CODE_TO_6 = '') or 
                   (@tcode_val6 = T_CODE_TO_6 and T_CODE_FROM_6 = '') or 
                   (T_CODE_FROM_6 = '' and T_CODE_TO_6 = '') ) 
              -- tcode 7 ranges
              and (@fld_tcode7 = '' or @tcode_val7 = '' or 
                   (@tcode_val7 between T_CODE_FROM_7 and T_CODE_TO_7) or 
                   (@tcode_val7 = T_CODE_FROM_7 and T_CODE_TO_7 = '') or 
                   (@tcode_val7 = T_CODE_TO_7 and T_CODE_FROM_7 = '') or 
                   (T_CODE_FROM_7 = '' and T_CODE_TO_7 = '') ) 
              -- tcode 8 ranges
              and (@fld_tcode8 = '' or @tcode_val8 = '' or 
                   (@tcode_val8 between T_CODE_FROM_8 and T_CODE_TO_8) or 
                   (@tcode_val8 = T_CODE_FROM_8 and T_CODE_TO_8 = '') or 
                   (@tcode_val8 = T_CODE_TO_8 and T_CODE_FROM_8 = '') or 
                   (T_CODE_FROM_8 = '' and T_CODE_TO_8 = '') ) 
              -- tcode 9 ranges
              and (@fld_tcode9 = '' or @tcode_val9 = '' or 
                   (@tcode_val9 between T_CODE_FROM_9 and T_CODE_TO_9) or 
                   (@tcode_val9 = T_CODE_FROM_9 and T_CODE_TO_9 = '') or 
                   (@tcode_val9 = T_CODE_TO_9 and T_CODE_FROM_9 = '') or 
                   (T_CODE_FROM_9 = '' and T_CODE_TO_9 = '') ) 
              -- tcode 10 ranges
              and (@fld_tcode10 = '' or @tcode_val10 = '' or 
                   (@tcode_val10 between T_CODE_FROM_10 and T_CODE_TO_10) or 
                   (@tcode_val10 = T_CODE_FROM_10 and T_CODE_TO_10 = '') or 
                   (@tcode_val10 = T_CODE_TO_10 and T_CODE_FROM_10 = '') or 
                   (T_CODE_FROM_10 = '' and T_CODE_TO_10 = '') ) 
              -- qcode 1 ranges
              and (@fld_qcode1 = '' or @qcode_val1 = '' or 
                   (@qcode_val1 between Q_CODE_FROM_1 and Q_CODE_TO_1) or 
                   (@qcode_val1 = Q_CODE_FROM_1 and Q_CODE_TO_1 = '') or 
                   (@qcode_val1 = Q_CODE_TO_1 and Q_CODE_FROM_1 = '') or 
                   (Q_CODE_FROM_1 = '' and Q_CODE_TO_1 = '') ) 
              -- qcode 2 ranges
              and (@fld_qcode2 = '' or @qcode_val2 = '' or 
                   (@qcode_val2 between Q_CODE_FROM_2 and Q_CODE_TO_2) or 
                   (@qcode_val2 = Q_CODE_FROM_2 and Q_CODE_TO_2 = '') or 
                   (@qcode_val2 = Q_CODE_TO_2 and Q_CODE_FROM_2 = '') or 
                   (Q_CODE_FROM_2 = '' and Q_CODE_TO_2 = '') ) 
              -- qcode 3 ranges
              and (@fld_qcode3 = '' or @qcode_val3 = '' or 
                   (@qcode_val3 between Q_CODE_FROM_3 and Q_CODE_TO_3) or 
                   (@qcode_val3 = Q_CODE_FROM_3 and Q_CODE_TO_3 = '') or 
                   (@qcode_val3 = Q_CODE_TO_3 and Q_CODE_FROM_3 = '') or 
                   (Q_CODE_FROM_3 = '' and Q_CODE_TO_3 = '') ) 
              -- qcode 4 ranges
              and (@fld_qcode4 = '' or @qcode_val4 = '' or 
                   (@qcode_val4 between Q_CODE_FROM_4 and Q_CODE_TO_4) or 
                   (@qcode_val4 = Q_CODE_FROM_4 and Q_CODE_TO_4 = '') or 
                   (@qcode_val4 = Q_CODE_TO_4 and Q_CODE_FROM_4 = '') or 
                   (Q_CODE_FROM_4 = '' and Q_CODE_TO_4 = '') ) 
              -- qcode 5 ranges
              and (@fld_qcode5 = '' or @qcode_val5 = '' or 
                   (@qcode_val5 between Q_CODE_FROM_5 and Q_CODE_TO_5) or 
                   (@qcode_val5 = Q_CODE_FROM_5 and Q_CODE_TO_5 = '') or 
                   (@qcode_val5 = Q_CODE_TO_5 and Q_CODE_FROM_5 = '') or 
                   (Q_CODE_FROM_5 = '' and Q_CODE_TO_5 = '') )
              -- qcode 6 ranges
              and (@fld_qcode6 = '' or @qcode_val6 = '' or 
                   (@qcode_val6 between Q_CODE_FROM_6 and Q_CODE_TO_6) or 
                   (@qcode_val6 = Q_CODE_FROM_6 and Q_CODE_TO_6 = '') or 
                   (@qcode_val6 = Q_CODE_TO_6 and Q_CODE_FROM_6 = '') or 
                   (Q_CODE_FROM_6 = '' and Q_CODE_TO_6 = '') ) 
              -- qcode 7 ranges
              and (@fld_qcode7 = '' or @qcode_val7 = '' or 
                   (@qcode_val7 between Q_CODE_FROM_7 and Q_CODE_TO_7) or 
                   (@qcode_val7 = Q_CODE_FROM_7 and Q_CODE_TO_7 = '') or 
                   (@qcode_val7 = Q_CODE_TO_7 and Q_CODE_FROM_7 = '') or 
                   (Q_CODE_FROM_7 = '' and Q_CODE_TO_7 = '') ) 
              -- qcode 8 ranges
              and (@fld_qcode8 = '' or @qcode_val8 = '' or 
                   (@qcode_val8 between Q_CODE_FROM_8 and Q_CODE_TO_8) or 
                   (@qcode_val8 = Q_CODE_FROM_8 and Q_CODE_TO_8 = '') or 
                   (@qcode_val8 = Q_CODE_TO_8 and Q_CODE_FROM_8 = '') or 
                   (Q_CODE_FROM_8 = '' and Q_CODE_TO_8 = '') ) 
              -- qcode 9 ranges
              and (@fld_qcode9 = '' or @qcode_val9 = '' or 
                   (@qcode_val9 between Q_CODE_FROM_9 and Q_CODE_TO_9) or 
                   (@qcode_val9 = Q_CODE_FROM_9 and Q_CODE_TO_9 = '') or 
                   (@qcode_val9 = Q_CODE_TO_9 and Q_CODE_FROM_9 = '') or 
                   (Q_CODE_FROM_9 = '' and Q_CODE_TO_9 = '') ) 
              -- qcode 10 ranges
              and (@fld_qcode10 = '' or @qcode_val10 = '' or 
                   (@qcode_val10 between Q_CODE_FROM_10 and Q_CODE_TO_10) or 
                   (@qcode_val10 = Q_CODE_FROM_10 and Q_CODE_TO_10 = '') or 
                   (@qcode_val10 = Q_CODE_TO_10 and Q_CODE_FROM_10 = '') or 
                   (Q_CODE_FROM_10 = '' and Q_CODE_TO_10 = '') ) 
            order by m.EXCEPTION_AUTHORITY

            open app_cursor
            fetch next from app_cursor into
              @excep_auth, @row_no, @line_no,
              @app_grp_id1, @app_grp_id2, @app_grp_id3,
              @app_grp_id4, @app_grp_id5, @app_grp_id6

            while @@fetch_status = 0
              begin
                if (@IN_EXCEPTION_AUTHORITY = @excep_auth) or
                   (@IN_EXCEPTION_AUTHORITY = 'B')
                  begin
                    if (@IN_EXCEPTION_AUTHORITY = 'B') and (@excep_auth = 'Y') and (@normal_app = 'Y')  -- only look at exection authority if no approvers found
                      break
                    set @approver = ''

                    -- return the approver's name
                    set @next_lvl = @lvl
                    if @IN_MATRIX_TYPE = 'I'    -- only increment if Invoice mattrix as requisition approval level are incremented by .NET code
                      set @next_lvl = @next_lvl + 1
                    else if @next_lvl = 0       -- Req / Req Hdr may not have been submitted
                      set @next_lvl = 1

                    if @IN_NEXT_LEVEL = 'Y'
                      set @next_lvl = @next_lvl + 1

                    while @next_lvl < 7
                      begin
                        set @approver = case @next_lvl
                                          when 1 then isnull(@app_grp_id1,'')
                                          when 2 then isnull(@app_grp_id2,'')
                                          when 3 then isnull(@app_grp_id3,'')
                                          when 4 then isnull(@app_grp_id4,'')
                                          when 5 then isnull(@app_grp_id5,'')
                                          when 6 then isnull(@app_grp_id6,'')
                                        end
                        if rtrim(@approver) <> ''
                          break
                        set @next_lvl = @next_lvl + 1
                      end

                    if (@lvl_found = -1) and (rtrim(isnull(@approver,'')) <> '')  -- approver found so assign lvl_found
                      set @lvl_found = @next_lvl

                    if (@lvl_found > -1) and (@next_lvl > @lvl_found)    -- gone past current level
                      begin
                        set @approver = case @lvl_found
                                          when 1 then isnull(@app_grp_id1,'')
                                          when 2 then isnull(@app_grp_id2,'')
                                          when 3 then isnull(@app_grp_id3,'')
                                          when 4 then isnull(@app_grp_id4,'')
                                          when 5 then isnull(@app_grp_id5,'')
                                          when 6 then isnull(@app_grp_id6,'')
                                        end
                      end

                    if @next_lvl < @lvl_found
                      begin
                        set @lvl_found = @next_lvl
                        set @next_approver = ''
                        delete from @tmp_table
                      end

                    if (@approver <> '')
                      begin
                        if @excep_auth = 'N'
                          set @normal_app = 'Y'
                        -- inserting to a table so that the output can be in alphabetical order
                        insert into @tmp_table (APPROVER) 
                        select dbo.PA_IPOS_NAME_FROM_USER_ID_FN(dbo.PA_IPOS_REASSIGNED_APPROVER(a.SUN_DB, u.USER_ID))
                        from PA_REQ_APPROVER_USERS a with (nolock)
                          inner join PA_REQ_USERS u with (nolock) on (a.USER_ID = u.USER_ID and u.SUSPEND = 'N')
                        where a.SUN_DB = @IN_SUN_DB
                          and a.APPROVER_ID = @approver
                        
                      end
                  end
                fetch next from app_cursor into
                  @excep_auth, @row_no, @line_no,
                  @app_grp_id1, @app_grp_id2, @app_grp_id3,
                  @app_grp_id4, @app_grp_id5, @app_grp_id6
              end
            close app_cursor
            deallocate app_cursor
          end
          -- rebuild next_approver variable to sort the approvers alphabetically

          set @next_approver = ''
          set @approver = ''

          -- delete unwanted records
          if @lvl_found <> -1 and @IN_MATRIX_TYPE <> 'I' and exists(select 1 from @tmp_table)
            begin
              --BHOG-98S4C6 - Requestor is also level 2 approver for the requisition, 'approve own requisition' option is not ticked in user's group profile.
              --iPOS will display requestor name as approver for level 2 approval.This requisition should be submitted to admin user for level 2 approval as per level 1 approval function.
              delete tmp from @tmp_table tmp
                inner join PA_REQ_USERS u with (nolock) on (u.FULL_NAME = tmp.APPROVER)
                inner join PA_REQ_GROUP_USERS gu with (nolock) on (u.USER_ID = gu.USER_ID and gu.SUN_DB = @IN_SUN_DB)
                inner join PA_REQ_GROUPS g with (nolock) on (gu.SUN_DB = g.SUN_DB and gu.GROUP_ID = g.GROUP_ID)
                inner join PA_REQ_PROFILES p with (nolock) on (g.SUN_DB = p.SUN_DB and g.PROFILE_ID = p.PROFILE_ID)
              where p.REQ_APPROVE_OWN = 'N'
                and p.SUN_DB = @IN_SUN_DB
                and u.USER_ID = @submitted_by_guid
              -- insert admin user if all approves are deleted
              if not exists(select 1 from @tmp_table)
                insert into @tmp_table
                select dbo.PA_IPOS_NAME_FROM_USER_ID_FN(dbo.PA_IPOS_REASSIGNED_APPROVER(SUN_DB, ru.USER_ID))
                from PA_REQ_USERS ru with (nolock)
                where ru.ADMIN_USER = 'Y'
            end

          declare name_cursor cursor local for
            Select distinct APPROVER from @tmp_table order by APPROVER

          open name_cursor

          fetch next from name_cursor into @approver

          while @@fetch_status = 0
            begin
              if @next_approver <> ''
               set @next_approver = @next_approver + ', '
              set @next_approver = @next_approver + rtrim(@approver)
              fetch next from name_cursor into @approver
            end
          close name_cursor
          deallocate name_cursor

          if rtrim(isnull(@next_approver,'')) = ''
            begin
              if @lvl = -8
                set @next_approver = 'Deleted'
              else if @lvl = -9
                set @next_approver = 'Disputed'
              else if @lvl = 7 and
                      rtrim(isnull(@app_by_1,'')) = '' and rtrim(isnull(@app_by_2,'')) = '' and
                      rtrim(isnull(@app_by_3,'')) = '' and rtrim(isnull(@app_by_4,'')) = '' and
                      rtrim(isnull(@app_by_5,'')) = '' and rtrim(isnull(@app_by_6,'')) = ''
                set @next_approver = 'System managed approval'
              else if @lvl = 7
                set @next_approver = 'Approval complete'
              else
                set @next_approver = 'No approver found'
            end
          if @lvl_found = -1
            set @lvl_found = 7

          return '(' + convert(nvarchar(1), @lvl_found) + ')' + @next_approver
      end
