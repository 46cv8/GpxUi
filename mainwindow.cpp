#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "rungpx.h"

#include <QFileDialog>
#include <QDebug>
#include <QMessageBox>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    heightCollapsed = 0;
    ui->setupUi(this);
    setAdvanced(false);
    resize(sizeHint());

    connect(ui->actionAbout, SIGNAL(triggered()), this, SLOT(on_about()));
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::setAdvanced(bool isAdvanced)
{
    ui->widgetAdvanced->setHidden(!isAdvanced);
    ui->btnAdvancedToggle->setText(isAdvanced ? tr("Advanced <<") : tr("Advanced >>"));
}

void MainWindow::on_btnAdvancedToggle_clicked()
{
    setAdvanced(ui->widgetAdvanced->isHidden());
}

void MainWindow::on_tbtnInputGcode_clicked()
{
    QString s = QFileDialog::getOpenFileName();
    if (!s.isEmpty())
        ui->editInput->setText(s);
}

void MainWindow::on_btnTranslate_clicked()
{
    QFileInfo fi(ui->editInput->text());
    QDir dir(ui->editInput->text());
    QString sDefaultFileName = dir.absoluteFilePath(fi.completeBaseName() + ".x3g");

    QString sFileName = QFileDialog::getSaveFileName(this, tr("X3g Output File"),
        sDefaultFileName, tr("X3g (*.x3g *.s3g)"));
    if (sFileName.isEmpty())
        return; // user cancelled

    RunGpx rungpx;
    rungpx.Translate(ui->editInput->text(), sFileName);
}

void MainWindow::on_about()
{
    QMessageBox::about(this, "About GPX",
    "GPX 2.1-alpha-markwal\n\n" // GPX_VERSION
    "GPX was created by Dr. Henry Thomas (aka Wingcommander) in April 2013.\n\n"
    "Copyright (c) 2013 WHPThomas, All rights reserved.\n"

    "Additional changes Copyright (c) 2014, 2015 DNewman, All rights reserved.\n"
    "GpxUI (GUI) Copyright (c) 2015 Mark Walker, All rights reserved.\n\n"

    "GPX is a post process utility for converting gcode output from 3D slicing "
    "software like Cura, KISSlicer, S3DCreator and Slic3r to x3g files for standalone "
    "3D printing on Makerbot Cupcake, ThingOMatic, and Replicator 1/2/2x printers "
    "- with support for both stock and SailFish firmwares\n\n"

    "This program is free software; you can redistribute it and/or modify "
    "it under the terms of the GNU General Public License as published by "
    "the Free Software Foundation; either version 2 of the License, or "
    "(at your option) any later version.\n\n"

    "This program is distributed in the hope that it will be useful, "
    "but WITHOUT ANY WARRANTY; without even the implied warranty of "
    "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the "
    "GNU General Public License for more details."
    );
}
