// ============================================================================
// ROBÔ DE LEMBRETE — Reuniões de pré-embarque de AMANHÃ (envio por e-mail)
//
// É uma Edge Function do Supabase (roda no servidor, sozinha). NÃO faz parte do
// app AVV (HTML) — é uma peça separada e independente.
//
// O que faz: lê as reservas do Pós-Venda, encontra as que têm reunião de
// pré-embarque AMANHÃ (que ainda não foram realizadas) e dispara um e-mail de
// lembrete via Resend (https://resend.com).
//
// Segredos necessários (definir no Supabase → Edge Functions → Secrets):
//   RESEND_API_KEY  -> chave da sua conta Resend
//   LEMBRETE_EMAIL  -> e-mail que vai RECEBER o lembrete (ex.: o seu)
//   LEMBRETE_FROM   -> remetente (para testar use "onboarding@resend.dev";
//                      depois de verificar o domínio: "lembretes@avvsistema.com.br")
// (SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY já vêm prontos automaticamente.)
//
// Teste: depois de publicar, invoque a função manualmente (botão "Invoke" no
// painel, ou via URL). Quando funcionar, agendamos para rodar todo dia.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Data no fuso de Brasília (formato AAAA-MM-DD). offsetDias=1 => amanhã.
function dataBR(offsetDias = 0): string {
  const d = new Date(Date.now() + offsetDias * 86400000);
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Sao_Paulo",
    year: "numeric", month: "2-digit", day: "2-digit",
  }).format(d);
}

Deno.serve(async (_req) => {
  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const RESEND_KEY = Deno.env.get("RESEND_API_KEY");
    // LEMBRETE_EMAIL aceita vários destinatários separados por vírgula
    // (ex.: "voce@email.com, gerente@email.com").
    const PARA = (Deno.env.get("LEMBRETE_EMAIL") || "").split(",").map((s) => s.trim()).filter(Boolean);
    const DE = Deno.env.get("LEMBRETE_FROM") || "onboarding@resend.dev";

    if (!RESEND_KEY || PARA.length === 0) {
      return new Response(JSON.stringify({ erro: "Faltam os segredos RESEND_API_KEY e/ou LEMBRETE_EMAIL." }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const sb = createClient(SUPABASE_URL, SERVICE_KEY);
    const amanha = dataBR(1);

    // Lê o registro único do Pós-Venda (array de reservas dentro de "dados").
    const { data: row, error } = await sb.from("posvenda_dados").select("dados").eq("id", 1).maybeSingle();
    if (error) throw error;
    const reservas: any[] = (row?.dados as any[]) || [];

    // Filtra: pré-embarque amanhã, não cancelada e ainda não realizada.
    const doDia = reservas.filter((r) =>
      r && r.preEmbarqueData === amanha &&
      r.tripStatus !== "Cancelada" &&
      !r.preEmbarqueRealizadaData
    );

    let enviado = false;
    if (doDia.length > 0) {
      const itens = doDia.map((r) => {
        const nome = (r.passageiros && r.passageiros[0] && r.passageiros[0].nome) || "Viajante";
        const hora = r.preEmbarqueHora || "";
        const destino = r.destino || "";
        return `<li style="margin:6px 0"><strong>${hora}</strong> — ${nome}${destino ? " · " + destino : ""} <span style="color:#888">(${r.id || ""})</span></li>`;
      }).join("");

      const html = `
        <div style="font-family:Arial,sans-serif;color:#1c2434">
          <h2 style="color:#0d2a55">📅 Reuniões de pré-embarque amanhã (${amanha})</h2>
          <p>Você tem <strong>${doDia.length}</strong> reunião(ões) de pré-embarque marcada(s) para amanhã:</p>
          <ul>${itens}</ul>
          <p style="font-size:12px;color:#888">Lembrete automático do sistema AVV · TZ Viagens</p>
        </div>`;

      const resp = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { "Authorization": `Bearer ${RESEND_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from: DE,
          to: PARA,
          subject: `Pré-embarques de amanhã (${doDia.length}) — ${amanha}`,
          html,
        }),
      });
      enviado = resp.ok;
      if (!resp.ok) {
        const txt = await resp.text();
        return new Response(JSON.stringify({ amanha, encontrados: doDia.length, enviado: false, erro_resend: txt }), { status: 502, headers: { "Content-Type": "application/json" } });
      }
    }

    return new Response(JSON.stringify({ amanha, encontrados: doDia.length, enviado }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ erro: String((e as Error)?.message || e) }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
