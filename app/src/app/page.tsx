'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';
import { GeoMap } from '@/components/GeoMap';
import { ArchitectureDiagram } from '@/components/ArchitectureDiagram';

interface DemoNarrative {
  title: string;
  duration: string;
  thesis: string;
  tabs: any[];
}

export default function HomePage() {
  const [narrative, setNarrative] = useState<DemoNarrative | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/demo_narrative.json')
      .then((r) => r.json())
      .then(setNarrative)
      .catch(() => {});
    fetch('/api/data')
      .then((r) => r.json())
      .then(setData)
      .catch(() => {});
  }, []);

  const title = narrative?.title || 'SEA AWS Demo';

  const executiveCockpit = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="FFB Yield (Avg)" value="22.8 T/ha" status="neutral" />
        <KPICard title="OER Rate" value="21.4%" status="neutral" />
        <KPICard title="Replanting (YTD)" value="4.2K ha" status="neutral" />
        <KPICard title="Estates" value="412" status="neutral" />
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="lg:col-span-1">
          <GeoMap country="malaysia" markers={[{"label": "Penang", "value": "Fab: util 92%", "color": "green", "size": "lg"}, {"label": "Kuala Lumpur", "value": "HQ", "color": "blue", "size": "md"}, {"label": "Johor Bahru", "value": "Southern ops", "color": "green", "size": "md"}]} routes={[]} title="Geographic Overview" height={400} />
        </div>
        <div className="lg:col-span-1 grid grid-cols-1 gap-4">
          <Chart data={data?.timeseries || [{ period: 'Loading', value: 0 }]} type="line" xKey="period" yKeys={[{ key: 'value', name: 'T/ha' }]} title="FFB Yield Trend (Monthly)" />
          <Chart data={data?.categories || [{ category: 'Loading', count: 0 }]} type="bar" xKey="category" yKeys={[{ key: 'count', name: 'T/ha' }]} title="Productivity by Estate" />
        </div>
      </div>
      <DataTable columns={[
          { key: 'id', header: '#' },
          { key: 'name', header: 'Estate' },
          { key: 'status', header: 'Health' },
          { key: 'value', header: 'Yield T/ha' },
      ]} data={data?.entities || []} title="Estate Performance Dashboard" />
    </div>
  );

  const domainTab1 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="Harvest Interval" value="14 days" />
        <KPICard title="Palm Age (Avg)" value="12 yrs" />
        <KPICard title="Fertilizer Cost" value="RM 2.4K/ha" />
      </div>
      <Chart data={data?.detail || [{ x: 'Loading', y: 0 }]} type="area" xKey="x" yKeys={[{ key: 'y', name: 'T/ha' }]} title="Yield vs Palm Age" height={400} />
    </div>
  );

  const domainTab2 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart data={data?.breakdown || [{ label: 'A', value: 30 }, { label: 'B', value: 70 }]} type="pie" xKey="label" yKeys={[{ key: 'value', name: 'RM/ha' }]} title="Replanting ROI Model" />
        <ActionMemo persona={{ name: 'Dato Razak Hamid', role: 'VP Plantations' }} context={{}} onGenerate={async () => ({ subject: 'Action Required', body: 'AI-generated recommendation based on current data.', urgency: 'HIGH', actions: ['Accelerate replanting for >25yr palms', 'Deploy drone fertilizer for peat areas', 'Trial precision harvesting at pilot estates'] })} />
      </div>
    </div>
  );

  const askAiTab = (
    <div className="h-[600px]">
      <AskAI title="Ask AI" mode="sql" sampleQuestions={['Which estates have yield below 18T/ha?', 'Show fertilizer ROI by soil type', 'What is the optimal replanting schedule?']} onSubmit={async (question, mode) => ({ answer: `[Demo Mode] Response to: "${question}" (${mode} mode). Connect to Snowflake for live data.`, sql: mode === 'sql' ? 'SELECT * FROM CURATED.SUMMARY LIMIT 10;' : undefined })} />
    </div>
  );

  const architectureTab = (
    <ArchitectureDiagram
      snowflakeFeatures={['Dynamic Tables (5-min refresh)', 'ML Functions (Forecast + Anomaly)', 'Cortex Search + Agent', 'Semantic View + Intelligence']}
      awsServices={[{ name: 'Amazon S3', role: 'Strategy Docs' }, { name: 'Amazon S3 + Kinesis', role: 'Integration' }, { name: 'Amazon SNS', role: 'Integration' }, { name: 'Amazon QuickSight + Q', role: 'Integration' }]}
    />
  );

  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '📊', content: executiveCockpit },
    { id: 'domain-1', label: 'Agronomics', icon: '📈', content: domainTab1 },
    { id: 'domain-2', label: 'Planning', icon: '⚡', content: domainTab2 },
    { id: 'ask-ai', label: 'Ask AI', icon: '🤖', content: askAiTab },
    { id: 'architecture', label: 'Architecture', icon: '🏗️', content: architectureTab },
  ];

  return <AppLayout title={title} tabs={tabs} narrative={narrative} />;
}
